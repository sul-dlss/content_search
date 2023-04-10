# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IndexFullTextContent do
  describe '#run' do
    it 'adds content to solr' do
      allow(Search).to receive(:client).and_return(instance_double(RSolr::Client, update: nil))
      allow(PurlObject).to receive(:new).and_return(instance_double(PurlObject, to_solr: [{ id: 1, druid: 'x' }]))
      described_class.run('x')
      expect(Search.client).to have_received(:update).with(
        data: {
          delete: { query: 'druid:x' },
          add: [{ id: 1, druid: 'x' }]
        }.to_json,
        params: { commitWithin: 5000 }
      )
    end
  end
end
