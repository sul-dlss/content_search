# frozen_string_literal: true

# Remove content for a druid from the solr index
class GarbageCollectIndex
  def self.run
    response['response']['docs'].each do |doc|
      Search.client.delete_by_query("druid:#{doc['druid']}", params: { commit: true })
    end
  end

  def self.response
    Search.client.get(
      Settings.solr.highlight_path,
      params: {
        q: 'resource_id:druid',
        fl: 'druid,timestamp',
        fq: "timestamp:[* TO #{(Time.zone.now - 3.days).utc.iso8601}]",
        rows: 100
      }
    )
  end
  private_class_method :response
end
