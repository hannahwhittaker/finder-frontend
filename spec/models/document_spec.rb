require "spec_helper"

describe Document do
  let(:content_item) {
    content_item_hash = {
      content_item: "42ce66de-04f3-4192-bf31-8394538e0734",
      slug: "/a-finder",
      name: 'finder-name',
      links: {},
      details: {
        "show_summaries": show_summaries,
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

  let(:show_summaries) { true }
  let(:facets) { [] }
  let(:finder) do
    FinderPresenter.new(content_item, facets, ResultSet.new([], 0))
  end

  describe "initialization" do
    it 'defaults to nil without a public timestamp' do
      rummager_document = {
        title: 'A title',
        link: 'link.com',
        es_score: 0.005
      }
      document = described_class.new(rummager_document, 0)

      expect(document.public_timestamp).to be_nil
    end

    it 'does not break external links' do
      rummager_document = {
        title: 'A title',
        link: 'https://link.com/mature-cheeses'
      }
      document = described_class.new(rummager_document, 0)

      expect(document.path).to eq("https://link.com/mature-cheeses")
    end
  end

  describe "#metadata" do
    context 'one facet with type date' do
      let(:facets) {
        [
          FactoryBot.build(:date_facet, key: "filter_key")
        ]
      }
      let(:document_hash) {
        FactoryBot.build(:document_hash, 'filter_key' => "2019")
      }
      it 'gets metadata for a simple date value' do
        expected_hash =
          {
            name: "Filter key",
            type: "date",
            value: "2019"
          }
        expect(Document.new(document_hash, 1).metadata(finder)).to eq([expected_hash])
      end
    end
    context 'one facet with type text' do
      let(:facets) {
        [
          OptionSelectFacet.new({ 'key' => 'filter_key',
                                 'filterable' => true,
                                 'type' => 'text',
                                 'display_as_result_metadata' => true }, {})
        ]
      }
      describe 'Simple key value in document hash' do
        let(:document_hash) {
          FactoryBot.build(:document_hash, 'filter_key' => "metadata_label")
        }
        it 'gets metadata for a simple text value' do
          expected_hash =
            {
              id: 'filter_key',
              name: 'Filter key',
              value:  "metadata_label",
              labels: %w[metadata_label],
              type: "text",
            }
          expect(Document.new(document_hash, 1).metadata(finder)).to eq([expected_hash])
        end
        describe 'there is a short name in the facet' do
          let(:facets) {
            [
              FactoryBot.build(:option_select_facet, 'key' => 'organisations', 'short_name' => 'short name')
            ]
          }
          it 'replaces the name by a short name from the facet' do
            expect(Document.new(document_hash, 1).metadata(finder)).to match([include(name: 'short name')])
          end
        end
      end
      describe 'Simple key value in document hash' do
        let(:document_hash) {
          FactoryBot.build(:document_hash, 'filter_key' => "metadata_label")
        }
        it 'gets metadata for a simple text value' do
          expected_hash =
            {
              id: 'filter_key',
              name: 'Filter key',
              value:  "metadata_label",
              labels: %w[metadata_label],
              type: "text",
            }
          expect(Document.new(document_hash, 1).metadata(finder)).to eq([expected_hash])
        end
        describe 'there is a short name in the facet' do
          let(:facets) {
            [
              FactoryBot.build(:option_select_facet, 'key' => 'organisations', 'short_name' => 'short name')
            ]
          }
          it 'replaces the name by a short name from the facet' do
            expect(Document.new(document_hash, 1).metadata(finder)).to match([include(name: 'short name')])
          end
        end
      end
      describe 'Multiple values in the document hash' do
        let(:document_hash) {
          FactoryBot.build(:document_hash,
                           'filter_key' =>
                             [
                               { "label" => "metadata_label_1" },
                               { "label" => "metadata_label_2" },
                               { "label" => "metadata_label_3" }
                             ])
        }
        it 'gets metadata for a simple text value' do
          expected_hash =
            {
              id: 'filter_key',
              name: 'Filter key',
              value:  "metadata_label_1 and 2 others",
              labels: %w[metadata_label_1 metadata_label_2 metadata_label_3],
              type: "text",
            }
          expect(Document.new(document_hash, 1).metadata(finder)).to eq([expected_hash])
        end
      end
    end
    describe 'The key is an organisation / document collection' do
      let(:facets) {
        [FactoryBot.build(:option_select_facet, 'key' => 'organisations'),
         FactoryBot.build(:option_select_facet, 'key' => 'document_collections')]
      }
      let(:document_hash) {
        FactoryBot.build(:document_hash,
                         'organisations' => [{ "title" => "org_title" }],
                         'document_collections' => [{ "title" => "dc_title" }])
      }
      it 'it uses title instead of label' do
        expect(Document.new(document_hash, 1).metadata(finder)).
          to match_array([include(value: 'org_title'), include(value: 'dc_title')])
      end
    end
    describe 'the key is an organisation and the document is mainstream' do
      let(:facets) {
        [FactoryBot.build(:option_select_facet, 'key' => 'organisations')]
      }
      let(:document_hash) {
        FactoryBot.build(:document_hash,
                         'organisations' => [{ "title" => "org_title" }],
                         'content_store_document_type' => 'answer')
      }
      it 'removes the metadata' do
        expect(Document.new(document_hash, 1).metadata(finder)).to be_empty
      end
    end
  end

  describe "es_score" do
    subject(:instance) { described_class.new({ title: "Y", link: "/y", es_score: 0.005 }, 0) }

    it "es_score is 0.005" do
      expect(instance.es_score).to eq 0.005
    end
  end

  describe '#truncated_description' do
    context 'shows truncated description when description is present' do
      description = "The government has many departments. These departments are part of the government."
      truncated_description = "The government has many departments."

      subject(:instance_with_description) { described_class.new({ title: "Y", link: "/y", description: description }, 0) }
      subject(:instance_without_description) { described_class.new({ title: "Y", link: "/y" }, 0) }

      it 'should have truncated description' do
        expect(instance_with_description.truncated_description).to eq(truncated_description)
      end

      it 'should not have truncated description' do
        expect(instance_without_description.truncated_description).to eq(nil)
      end
    end
  end
end
