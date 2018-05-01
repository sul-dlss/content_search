# frozen_string_literal: true

# Index full text content into the solr index
class IndexFullTextContentJob < ApplicationJob
  def perform(druid)
    Search.client.update(
      data: {
        delete: { query: "druid:#{RSolr.solr_escape(druid)}" },
        add: PurlObject.new(druid).to_solr
      }.to_json,
      params: {
        commitWithin: 5000
      }
    )
  end
end
