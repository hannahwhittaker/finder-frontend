require 'spec_helper'

RSpec.describe SearchResultPresenter do
  let(:content_item) {
    content_item_hash = {
      content_item: content_id,
      base_path: link,
      title: 'finder-title',
      name: 'finder-name',
      links: {},
      details: {
        'show_summaries': show_summaries,
        "sort": [
          {
            "name": "Topic",
            "key": "topic",
            "default": true
          },
          {
            "name": "Most viewed",
            "key": "-popularity"
          }
        ],
      }
    }
    ContentItem.new(content_item_hash.deep_stringify_keys)
  }
  let(:content_id) { "42ce66de-04f3-4192-bf31-8394538e0734" }
  let(:show_summaries) { true }
  let(:facets) {
    []
  }
  let(:finder_presenter) { FinderPresenter.new(content_item, facets, search_results) }

  let(:search_results) {
    ResultSet.new([], 1)
  }

  let(:doc_index) { 0 }
  let(:doc_count) { 1 }
  let(:debug_score) { false }
  let(:highlight) { false }

  let(:metadata_presenter_class) { MetadataPresenter }

  subject(:presenter) {
    SearchResultPresenter.new(document: document,
                              metadata_presenter_class: metadata_presenter_class,
                              doc_count: doc_count,
                              finder_presenter: finder_presenter,
                              debug_score: debug_score,
                              highlight: highlight)
  }

  let(:document) {
    hash = FactoryBot.build(:document_hash,
                            title: title,
                            link: link,
                            description: description,
                            is_historic: is_historic,
                            government_name: 'Government!',
                            format: 'cake',
                            es_score: 0.005,
                            content_id: 'content_id',
                            filter_key: 'filter_value')
    Document.new(hash, 1)
  }

  let(:is_historic) { false }
  let(:title) { 'Investigation into the distribution of road fuels in parts of Scotland' }
  let(:link) { 'link-1' }
  let(:description) { 'I am a document. I am full of words and that.' }

  describe "#govuk_component_data" do
    it "returns a hash of the data we need to show the document" do
      expected_document = {
        link: {
          text: title,
          path: link,
          description: 'I am a document.',
          data_attributes: {
            ecommerce_path: link,
            ecommerce_content_id: 'content_id',
            ecommerce_row: 1,
            track_category: "navFinderLinkClicked",
            track_action: "finder-title.1",
            track_label: link,
            track_options: {
              dimension28: doc_count,
              dimension29: title
            }
          }
        },
        metadata: {},
        metadata_raw: [],
        subtext: nil,
        highlight: false,
        highlight_text: nil
      }
      expect(subject.document_list_component_data).to eql(expected_document)
    end
  end

  describe "structure_metadata" do
    context 'the eu exit finder' do
      let(:content_id) { "42ce66de-04f3-4192-bf31-8394538e0734" }
      it "returns nothing if finder displays metadata" do
        expect(subject.document_list_component_data[:metadata]).to eql({})
      end
    end

    context 'a text based facet' do
      let(:facets) { [FactoryBot.build(:option_select_facet, 'key' => 'filter_key')] }
      it 'displays text based metadata' do
        expect(presenter.document_list_component_data[:metadata]).to eq("Filter key" => "Filter key: filter_value")
      end
    end
    context 'a date based facet' do
      let(:facets) { [FactoryBot.build(:date_facet, 'key' => 'filter_key')] }
      let(:document) {
        hash = FactoryBot.build(:document_hash, filter_key: '10-10-2009')
        Document.new(hash, 1)
      }
      it 'displays date based metadata' do
        expect(presenter.document_list_component_data[:metadata]).
          to eq("Filter key" => 'Filter key: <time datetime="2009-10-10">10 October 2009</time>')
      end
    end
  end

  describe "subtext" do
    let(:historic_subtext) do
      "<span class=\"published-by\">First published during the Government!</span>"
    end
    let(:debug_subtext) do
      "<span class=\"debug-results debug-results--link\">link-1</span><span class=\"debug-results debug-results--meta\">"\
      "Score: 0.005</span><span class=\"debug-results debug-results--meta\">Format: cake</span>"
    end
    it "returns nothing unless is_historic or debug_score" do
      expect(subject.document_list_component_data[:subtext]).to eql(nil)
    end

    context 'is historic' do
      let(:is_historic) { true }
      it "returns 'Published by' text if is_historic is true" do
        expect(subject.document_list_component_data[:subtext]).to eql(historic_subtext)
      end
    end

    context 'debug_score is true' do
      let(:debug_score) { true }
      it "returns debug metadata if debug_score" do
        expect(subject.document_list_component_data[:subtext]).to eql(debug_subtext)
      end
    end

    context 'historic and debug_score' do
      let(:is_historic) { true }
      let(:debug_score) { true }
      it "returns 'Published by' and debug metadata together" do
        expect(subject.document_list_component_data[:subtext]).to eql("#{historic_subtext}#{debug_subtext}")
      end
    end
  end

  describe "summary_text" do
    context 'highlighted' do
      let(:highlight) { true }
      context 'show summaries' do
        let(:show_summaries) { true }
        it 'returns the truncated description' do
          expect(subject.document_list_component_data[:link][:description]).to eql("I am a document.")
        end
      end
      context 'do not show summaries' do
        let(:show_summaries) { false }
        it 'returns the truncated description' do
          expect(subject.document_list_component_data[:link][:description]).to eql("I am a document.")
        end
      end
    end
    context 'not highlighted' do
      let(:highlight) { false }
      context 'show summaries' do
        let(:show_summaries) { true }
        it 'returns the truncated description' do
          expect(subject.document_list_component_data[:link][:description]).to eql("I am a document.")
        end
      end
      context 'do not show summaries' do
        let(:show_summaries) { false }
        it 'returns the truncated description' do
          expect(subject.document_list_component_data[:link][:description]).to be_nil
        end
      end
    end
  end

  describe "highlight_text" do
    context 'not highlighted' do
      let(:highlight) { false }
      it "returns nothing" do
        expect(subject.document_list_component_data[:highlight_text]).to eql(nil)
      end
    end
    context 'highlighted' do
      let(:highlight) { true }
      it "returns 'Most relevant result'" do
        expect(subject.document_list_component_data[:highlight_text]).to eql("Most relevant result")
      end
    end
  end
end
