# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PurlObject do
  subject(:object) { described_class.new('x') }

  let(:public_cocina_json) do
    {
      modified: '2021-05-26T23:52:08Z',
      structural: {
        contains: [
          {
            externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/x-y',
            structural: {
              contains: [
                {
                  filename: 'y.txt',
                  hasMimeType: 'text/plain',
                  use: 'transcription',
                  administrative: {
                    shelve: true
                  }
                }
              ]
            }
          },
          {
            externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/x-oversize',
            structural: {
              contains: [
                {
                  filename: 'oversize.txt',
                  size: 100.gigabytes,
                  hasMimeType: 'text/plain',
                  use: 'transcription',
                  administrative: {
                    shelve: true
                  }
                }
              ]
            }
          }
        ]
      }
    }.to_json
  end

  let(:public_cocina_response) { instance_double(HTTP::Response, body: public_cocina_json) }

  before do
    purl_url = 'https://purl.stanford.edu/x.json'
    allow(described_class.client).to receive(:get).with(purl_url).and_return(public_cocina_response)
  end

  describe '#published' do
    it 'parses the published attr out of public XML' do
      expect(object.published).to eq('2021-05-26T23:52:08Z')
    end
  end

  describe '#ocr_files' do
    it 'has resources that are potentially OCR' do
      expect(object.ocr_files.map(&:filename)).to include 'y.txt'
    end

    it 'excludes resources that are unlikely to be OCR' do
      expect(object.ocr_files.map(&:filename)).not_to include 'oversize.txt'
    end
  end

  describe '#to_solr' do
    let(:ocr_text) { 'text text text' }
    let(:ocr_response) { instance_double(HTTP::Response, body: ocr_text, status: instance_double(HTTP::Response::Status, success?: true)) }

    before do
      stacks_url = 'https://stacks.stanford.edu/file/x/y.txt'
      mock_client = double
      allow(mock_client).to receive(:get).with(stacks_url).and_return(ocr_response)

      allow(PurlObject::File).to receive(:client).and_return(mock_client)
    end

    it 'creates an indexable hash of OCR content' do
      expect(object.to_solr.to_a).to include id: 'x/cocina-fileSet-x-y/y.txt',
                                             druid: 'x',
                                             resource_id: 'cocina-fileSet-x-y',
                                             filename: 'y.txt',
                                             ocrtext: ['text text text']
    end

    it 'indexes the published date' do
      expect(object.to_solr).to include id: 'x',
                                        druid: 'x',
                                        published: '2021-05-26T23:52:08Z',
                                        resource_id: 'druid'
    end

    context 'with a file without content on stacks' do
      let(:ocr_response) { instance_double(HTTP::Response, status: instance_double(HTTP::Response::Status, success?: false)) }

      before do
        stacks_url = 'https://stacks.stanford.edu/file/x/y.txt'
        mock_client = double
        allow(mock_client).to receive(:get).with(stacks_url).and_return(ocr_response)

        allow(PurlObject::File).to receive(:client).and_return(mock_client)
      end

      it 'does nothing' do
        expect(object.to_solr.to_a.length).to eq 1
      end
    end
  end
end
