# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BuildSuggestJob do
  describe '#perform' do
    it 'sends a suggest.build to Solr' do
      allow(Search).to receive(:client).and_return(instance_double(RSolr::Client, send_and_receive: nil))
      described_class.perform_now
      expect(Search.client).to have_received(:send_and_receive).with('suggest', params: { 'suggest.build' => true })
    end
  end
end
