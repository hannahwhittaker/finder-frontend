require 'spec_helper'
require 'gds_api/test_helpers/search'

describe HomeController, type: :controller do
  include GdsApi::TestHelpers::Search

  render_views

  describe "homepage" do
    before do
      rummager_response = %|{
        "results": [],
        "total": 38,
        "start": 0,
        "facets": {
          "content_store_document_type": {
            "options": [
              {
                "value": {
                  "slug": "finder",
                  "example_info": {
                    "total": 2,
                    "examples": [
                      {
                        "link": "/search/all",
                        "title": "Search"
                      },
                      {
                        "link": "/government/organisations/hm-revenue-customs/contact",
                        "title": "Contact HM Revenue & Customs"
                      }
                    ]
                  }
                },
                "documents": 38
              }
            ]
          }
        }
      }|

      url = "#{Plek.current.find('search')}/search.json"

      stub_request(:get, url)
        .with(query: {
          filter_rendering_app: "finder-frontend",
          facet_content_store_document_type: "100,examples:100,example_scope:query",
          count: 0
        })
        .to_return(status: 200, body: rummager_response, headers: {})
    end

    it "correctly renders the finder-frontend homepage" do
      get :index
      expect(response.status).to eq(200)
      expect(response).to render_template("home/index")

      expect(response.body).to include("Example pages rendered by finder-frontend")
      expect(response.body).to include("Finders by most visited (2)")
    end
  end
end
