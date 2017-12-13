# frozen_string_literal: true

# Index full text content into the solr index
class IndexFullTextContentJob < ApplicationJob
  def perform(druid)
    Search.client.add(PurlObject.new(druid).to_solr, commitWithin: 5000)
  end
end
