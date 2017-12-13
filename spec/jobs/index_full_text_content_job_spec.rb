# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IndexFullTextContentJob do
  describe '#perform' do
    it 'adds content to solr' do
      allow(Search).to receive(:client).and_return(instance_double(RSolr::Client, add: nil))
      allow(PurlObject).to receive(:new).and_return(instance_double(PurlObject, to_solr: [{ id: 1 }]))
      described_class.perform_now('x')
      expect(Search.client).to have_received(:add).with([{ id: 1 }], commitWithin: 5000)
    end
  end
end
