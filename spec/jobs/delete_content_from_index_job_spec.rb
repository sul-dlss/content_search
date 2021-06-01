# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DeleteContentFromIndexJob do
  describe '#perform' do
    it 'adds content to solr' do
      allow(Search).to receive(:client).and_return(instance_double(RSolr::Client, delete_by_query: nil))
      described_class.perform_now('x')
      expect(Search.client).to have_received(:delete_by_query).with('druid:x', params: { commit: true })
    end
  end
end
