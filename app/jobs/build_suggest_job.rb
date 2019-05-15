# frozen_string_literal: true

# Update the Spellcheck database to enable autocomplete
class BuildSuggestJob < ApplicationJob
  def perform
    Search.client.send_and_receive(
      'suggest',
      params: { 'suggest.build' => true }
    )
  end
end
