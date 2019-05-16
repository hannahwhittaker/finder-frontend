class HomeController < ApplicationController
  layout 'finder_layout'

  def index
    render 'index', locals: { examples_by_doc_type: examples_by_doc_type }
  end

private

  def search_query_params
    {
      filter_rendering_app: "finder-frontend",
      facet_content_store_document_type: "100,examples:100,example_scope:query",
      count: 0
    }
  end

  def result
    @result ||= Services.rummager.search(search_query_params)
  end

  def examples_by_doc_type
    result.dig("facets", "content_store_document_type", "options").reduce({}) do |hash, option|
      hash[option.dig("value", "slug")] = contents_list_item_from_example(option)
      hash
    end
  end

  def contents_list_item_from_example(option)
    option.dig("value", "example_info", "examples").map do |example|
      {
        href: example['link'],
        text: example['title']
      }
    end
  end
end
