# frozen_string_literal: true

# Update the Spellcheck database to enable autocomplete
class BuildCollectionSuggestJob < ApplicationJob
  def perform
    collection = Collection.new
    collection.build_suggest
  end
end
