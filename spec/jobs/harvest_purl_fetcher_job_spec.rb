# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HarvestPurlFetcherJob do
  before do
    allow(PurlFetcher::Client::DeletesReader).to receive(:new).with('', anything).and_return(deletes_reader)
    allow(PurlFetcher::Client::Reader).to receive(:new).with('', anything).and_return(reader)
  end

  let(:deletes_reader) do
    [
      instance_double(PurlFetcher::Client::PublicXmlRecord, druid: 'delete_a'),
      instance_double(PurlFetcher::Client::PublicXmlRecord, druid: 'delete_b')
    ]
  end

  let(:time) { '2018-09-18T01:02:03' }

  let(:reader) do
    o = Object.new

    def o.each
      return to_enum(:each) unless block_given?

      yield(OpenStruct.new(druid: 'new_c'), 'updated_at' => nil)
      yield(OpenStruct.new(druid: 'new_d'), 'updated_at' => nil)
    end

    dbl = instance_double(PurlFetcher::Client::Reader, range: { 'last_updated' => time })
    allow(dbl).to receive(:each_slice) { |&block| o.each.each_slice(100, &block) }
    dbl
  end

  describe '#perform' do
    before do
      allow(DeleteContentFromIndexJob).to receive(:perform_later).with(anything)
      allow(IndexFullTextContentJob).to receive(:perform_later).with(anything)
    end

    it 'resumes from a provided timestamp' do
      ts = '2018-01-01T01:23:45'
      described_class.perform_now(ts)
      expect(PurlFetcher::Client::Reader).to have_received(:new).with('', 'purl_fetcher.first_modified' => ts)
      expect(PurlFetcher::Client::DeletesReader).to have_received(:new).with('', 'purl_fetcher.first_modified' => ts)
    end

    it 'tracks the most recently retrieved timestamp' do
      described_class.perform_now

      expect(File.read(described_class::STATE_FILE).strip).to eq time
    end

    it 'deletes content' do
      described_class.perform_now

      expect(DeleteContentFromIndexJob).to have_received(:perform_later).with('delete_a')
      expect(DeleteContentFromIndexJob).to have_received(:perform_later).with('delete_b')
    end

    it 'indexes content' do
      described_class.perform_now

      expect(IndexFullTextContentJob).to have_received(:perform_later).with('new_c')
      expect(IndexFullTextContentJob).to have_received(:perform_later).with('new_d')
    end
  end
end
