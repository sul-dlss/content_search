# frozen_string_literal: true

# Solr search model
class Search
  include ActiveSupport::Benchmarkable

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
    highlight_response['highlighting'].map do |id, fields|
      [id, fields.values.flatten.uniq]
    end.to_h
  end

  ##
  # Returns a modified result list from Solr, by following the following:
  # - Remove duplicates by case (e.g. The, the)
  # - Sort by "weight" (occurance) and then by length. This helps to sort values
  #   for recurring sequences.
  #   "the cou": ["the Court", "the Court decided", "the Court decided to"]
  # - Take the last 5 results
  # rubocop:disable Metrics/AbcSize
  def suggestions
    suggest_response['suggest'].values.first[q]['suggestions']
                               .uniq { |s| s['term'].downcase }
                               .sort_by { |s| (-s['weight']) * 100 + s['term'].length }
                               .take(5)
  end
  # rubocop:enable Metrics/AbcSize

  private

  def highlight_response
    @highlight_response ||= get(Settings.solr.highlight_path, params: highlight_request_params)
  end

  def suggest_response
    @suggest_response ||= get(Settings.solr.suggest_path, params: suggest_request_params)
  end

  def get(url, params:)
    p = params.reverse_merge(q: q)
    benchmark "Fetching Search#get(#{url}, params: #{p})", level: :debug do
      self.class.client.get(url, params: p)
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
end
