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
  let(:reader) do
    [
      instance_double(PurlFetcher::Client::PublicXmlRecord, druid: 'new_c'),
      instance_double(PurlFetcher::Client::PublicXmlRecord, druid: 'new_d', public_xml_doc: doc)
    ]
  end
  let(:doc) { Nokogiri::XML('<publicObject published="2018-09-18T01:02:03" />') }

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

      expect(File.read(described_class::STATE_FILE).strip).to eq '2018-09-18T01:02:03'
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
