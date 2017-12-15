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
    response['response']['numFound']
  end

  def highlights
    response['highlighting'].map do |id, fields|
      [id, fields['ocrtext']]
    end.to_h
  end

  private

  def response
    @response ||= self.class.client.get(Settings.solr.path, params: request_params)
  end

  def request_params
    Settings.solr.highlight_params.to_h.merge(
      q: q,
      fq: ["druid:#{id}"],
      rows: rows,
      start: start
    )
  end
end
