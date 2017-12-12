require 'spec_helper'
require 'alto_indexer'

RSpec.describe AltoIndexer do
  subject(:indexer) { described_class.new('x', 'y', File.read('spec/fixtures/bb018zb8894_04_0009.xml')) }
  describe '#to_solr' do
    it 'creates a solr document for indexing' do
      expect(indexer.to_solr).to include id: 'x/y', druid: 'x', resource_id: 'y', ocrtext: start_with('George')
    end
  end
end
