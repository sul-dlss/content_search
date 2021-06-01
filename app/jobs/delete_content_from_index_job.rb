# frozen_string_literal: true

# Remove content for a druid from the solr index
class DeleteContentFromIndexJob < ApplicationJob
  def perform(druid)
    Search.client.delete_by_query("druid:#{druid}", params: { commit: true })
  end
end
