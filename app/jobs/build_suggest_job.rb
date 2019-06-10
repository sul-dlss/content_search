# frozen_string_literal: true

# Update the Spellcheck database to enable autocomplete
class BuildSuggestJob < ApplicationJob
  def perform(url, collection_name)
    conn = Faraday.new(url)
    conn.get do |req|
      req.url "#{collection_name}/suggest", 'suggest.build' => true
    end
  end
end
