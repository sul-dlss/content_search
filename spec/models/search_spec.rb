# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search do
  subject(:search) { described_class.new('x', q: 'y') }

  describe '.client' do
    it 'returns an RSolr client' do
      expect(described_class.client).to be_a_kind_of RSolr::Client
    end

    it 'uses settings to configure the solr url' do
      expect(described_class.client.uri.to_s).to eq Settings.solr.url
    end
  end

  describe '#highlights' do
    it 'transforms Solr responses into a hash' do
      highlights = { 'ocrtext' => %w[1 2], 'ocrtext_lang' => %w[2 3] }
      client = instance_double(RSolr::Client, get: { 'highlighting' => { 'x' => highlights } })
      allow(described_class).to receive(:client).and_return(client)
      expect(search.highlights).to include 'x' => match_array(%w[1 2 3])
    end
  end

  describe '#suggestions' do
    it 'transforms Solr responses into an array of suggestions' do
      suggestions = { 'y' => { 'suggestions' => [
        { 'term' => 'termA', 'weight' => 1 }, { 'term' => 'termB', 'weight' => 2 }
      ] } }
      client = instance_double(RSolr::Client, get: { 'suggest' => { 'mySuggester' => suggestions } })
      allow(described_class).to receive(:client).and_return(client)
      expect(search.suggestions).to match_array [{ 'term' => 'termB', 'weight' => 2 }, { 'term' => 'termA', 'weight' => 1 }]
    end
  end

  describe '#num_found' do
    it 'gets the number of hits from the solr response' do
      client = instance_double(RSolr::Client, get: { 'response' => { 'numFound' => 15 } })
      allow(described_class).to receive(:client).and_return(client)
      expect(search.num_found).to eq 15
    end
  end
end
