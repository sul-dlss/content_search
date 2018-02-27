# frozen_string_literal: true

# Solr search model
class Search
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
  # - Take the last 5 results
  # - Remove duplicates by case (e.g. The, the)
  # - Sort by "weight" (occurance) and then by length. This helps to sort values
  #   for recurring sequences.
  #   "the cou": ["the Court", "the Court decided", "the Court decided to"]
  # rubocop:disable Metrics/AbcSize
  def suggestions
    suggest_response['suggest'].values.first[q]['suggestions'].take(5)
                               .uniq { |s| s['term'].downcase }
                               .sort_by { |s| [-s['weight'], s['term'].length] }
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
    self.class.client.get(url, params: params.reverse_merge(q: q))
  end

  def highlight_request_params
    Settings.solr.highlight_params.to_h.merge(
      fq: ["druid:#{id}"],
      rows: rows,
      start: start
    )
  end

  def suggest_request_params
    Settings.solr.suggest_params.to_h.merge(
      'suggest.cfq' => id
    )
  end
end
