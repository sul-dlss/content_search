# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search do
  subject(:search) { described_class.new('x', q: 'y') }

  before do
    allow(search).to receive(:bookkeep!).and_return(nil) # rubocop:disable RSpec/SubjectStub
  end

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
      client = instance_double(RSolr::Client, get: { 'response' => { 'numFound' => 3 }, 'highlighting' => { 'x' => highlights } })
      allow(described_class).to receive(:client).and_return(client)
      expect(search.highlights).to include 'x' => match_array(%w[1 2 3])
    end

    it 'kicks off indexing if no results were found' do
      client = instance_double(RSolr::Client, get: { 'response' => { 'numFound' => 0 }, 'highlighting' => {} })
      allow(described_class).to receive(:client).and_return(client)
      allow(IndexFullTextContentJob).to receive(:perform_now)
      search.highlights
      expect(IndexFullTextContentJob).to have_received(:perform_now).with('x', commit: true)
    end
  end

  describe '#suggestions' do
    let(:suggestions) { { 'y' => { 'numFound' => 10, 'suggestions' => suggestion_values } } }
    let(:suggestion_values) do
      [
        { 'term' => 'termA', 'weight' => 1 },
        { 'term' => 'termB', 'weight' => 2 },
        { 'term' => 'termb', 'weight' => 2 },
        { 'term' => 'termC', 'weight' => 2 },
        { 'term' => 'termD', 'weight' => 2 },
        { 'term' => 'termE', 'weight' => 2 },
        { 'term' => 'termFF', 'weight' => 3 },
        { 'term' => 'termF', 'weight' => 3 },
        { 'term' => 'termGgg', 'weight' => 2 }
      ]
    end

    before do
      client = instance_double(RSolr::Client, get: { 'suggest' => { 'mySuggester' => suggestions } })
      allow(described_class).to receive(:client).and_return(client)
    end

    it 'grabs unique terms by case' do
      expect(search.suggestions.count { |s| s['term'].casecmp('termb').zero? }).to eq 1
    end

    it 'sorts the values by weight and then reverse length' do
      expect(search.suggestions).to match_array [
        { 'term' => 'termF', 'weight' => 3 },
        { 'term' => 'termFF', 'weight' => 3 },
        { 'term' => 'termB', 'weight' => 2 },
        { 'term' => 'termC', 'weight' => 2 },
        { 'term' => 'termD', 'weight' => 2 }
      ]
    end

    it 'takes the last 5' do
      expect(search.suggestions.count).to eq 5
    end

    it 'kicks off indexing and suggestions build if no results were found' do
      client = instance_double(RSolr::Client, get: { 'response' => { 'numFound' => 0 } })
      allow(described_class).to receive(:client).and_return(client)
      allow(IndexFullTextContentJob).to receive(:perform_now)
      allow(BuildSuggestJob).to receive(:perform_now)
      search.suggestions
      expect(IndexFullTextContentJob).to have_received(:perform_now).with('x', commit: true)
      expect(BuildSuggestJob).to have_received(:perform_now)
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
