# frozen_string_literal: true

# Solr collection model
class Collection
  def self.client
    RSolr.connect(url: base_url)
  end

  def self.collection_name
    Settings.solr.url
            .gsub(
              %r{https?:\/\/.*\/solr\/}, ''
            )
            .gsub(
              %r{\/$}, ''
            )
  end

  def self.base_url
    Settings.solr.url.match(%r{https?:\/\/.*\/solr})[0].delete('solr')
  end

  def cluster_status
    self.class.client.send_and_receive(
      'solr/admin/collections',
      params: {
        action: 'clusterstatus',
        collection: self.class.collection_name
      }
    )
  end

  def shards
    ActiveSupport::HashWithIndifferentAccess
      .new(cluster_status)
      .dig('cluster', 'collections', self.class.collection_name.to_s, 'shards')
  end

  def replicas
    shards.map do |_k, v|
      v.dig(:replicas).map do |_k1, v1|
        v1.dig(:base_url)
      end
    end.flatten.compact
  end

  def build_suggest
    replicas.map do |url|
      BuildSuggestJob.perform_later(url, self.class.collection_name)
    end
  end
end
