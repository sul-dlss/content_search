# frozen_string_literal: true

# Transforming search highlighting results into IIIF Content Search API responses
class IiifAutocompleteResponse
  attr_reader :search, :controller

  delegate :request, to: :controller

  def initialize(search, controller)
    @search = search
    @controller = controller
  end

  def as_json(*_args)
    {
      "@context": [
        'http://iiif.io/api/search/1/context.json'
      ],
      "@id": request.original_url,
      "@type": 'search:TermList',
      "ignored": ignored_params,
      "terms": terms.map(&:as_json)
    }
  end

  private

  def match_url(q)
    controller.iiif_content_search_url(id: search.id, q: "\"#{q}\"")
  end

  def ignored_params
    Settings.iiif.ignored_request_params.select { |param| controller.params.keys.include?(param) }
  end

  def terms
    search.suggestions.map do |suggestion|
      {
        match: suggestion['term'],
        url: match_url(suggestion['term']),
        count: suggestion['weight']
      }
    end
  end
end
