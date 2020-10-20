# frozen_string_literal: true

# Index full text content into the solr index
class IndexFullTextContentJob < ApplicationJob
  def perform(druid, options = { commitWithin: 5000 })
    Search.client.update(
      data: {
        delete: { query: "druid:#{RSolr.solr_escape(druid)}" },
        add: PurlObject.new(druid).to_solr
      }.to_json,
      params: options
    )
  end
end
