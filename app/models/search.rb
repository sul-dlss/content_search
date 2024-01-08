# frozen_string_literal: true

# Solr search model
class Search
  include ActiveSupport::Benchmarkable
  include Locking

  attr_reader :id, :q, :start, :rows

  def self.client
    RSolr.connect(url: Settings.solr.url)
  end

  def initialize(id, q:, start: 0)
    @id = id
    @q = q
    @start = start
    @rows = 100
  end

  def num_found
    highlight_response['response']['numFound']
  end

  def highlights
    highlight_response['highlighting'].transform_values do |fields|
      fields.values.flatten.uniq
    end
  end

  private

  def highlight_response
    @highlight_response ||= begin
      response = get(Settings.solr.highlight_path, params: highlight_request_params)

      if response.dig('response', 'numFound')&.zero?
        reindex_document

        response = get(Settings.solr.highlight_path, params: highlight_request_params)
      end

      response.tap { bookkeep! }
    end
  end

  def suggest_response
    @suggest_response ||= begin
      response = suggest_request
      response = suggest_request(rebuild: true) if response.nil? || (response['suggest']&.values&.dig(0, q, 'numFound') || 0)&.zero?

      response.tap { bookkeep! }
    end
  end

  def suggest_request(rebuild: false)
    rebuild_suggester if rebuild
    get(Settings.solr.suggest_path, params: suggest_request_params)
  rescue RSolr::Error::Http => e
    raise(e) unless e&.response&.dig(:body)&.include?('suggester was not built')

    nil
  end

  def get(url, params:)
    p = params.reverse_merge(q: q)
    benchmark "Fetching Search#get(#{url}, params: #{p})", level: :debug do
      self.class.client.get(url, params: p)
    end
  end

  def any_results_for_document?
    response = get(Settings.solr.highlight_path,
                   params: { q: "druid:#{id}", rows: 0, fl: 'id', fq: ['resource_id:druid', "published:\"#{published}\""] })

    response['response']['numFound'].positive?
  end

  def reindex_document
    with_lock("indexing_lock_#{id.parameterize}") do |locked_on_first_try|
      next if !locked_on_first_try || any_results_for_document?

      IndexFullTextContent.run(id, commit: true)
    end
  end

  def rebuild_suggester
    reindex_document

    with_lock "indexing_lock_suggester_#{id}" do |locked_on_first_try|
      BuildSuggestJob.perform_now if locked_on_first_try
    end
  end

  def highlight_request_params
    Settings.solr.highlight_params.to_h.merge(
      fq: ["druid:#{id}"],
      rows: rows,
      start: start,
      'hl.tag.ellipsis' => ' ' # Gives the after block in missing cases
    )
  end

  def suggest_request_params
    Settings.solr.suggest_params.to_h.merge(
      'suggest.cfq' => id
    )
  end

  def logger
    Rails.logger
  end

  def published
    @published ||= PurlObject.new(id).published
  end

  # Do some bookkeeping to keep track of the last time this record was used
  def bookkeep!
    # We inject the published value because ... threads. Just to be safe.
    Thread.new(published) do |published_value|
      Search.client.add([{ id: id, druid: id, published: published_value, resource_id: 'druid' }],
                        add_attributes: { commitWithin: (1.hour.to_i * 1000) })
    end
  end
end
