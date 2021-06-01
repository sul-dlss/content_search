# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PurlObject do
  subject(:object) { described_class.new('x') }

  let(:public_xml) do
    <<-XML
    <publicObject published="2021-05-26T23:52:08Z">
      <contentMetadata>
        <resource id="y">
          <file id="y.txt" mimetype="text/plain" role="transcription" />
        </resource>
        <resource id="oversize">
          <file id="oversize.txt" size="#{100.gigabytes}" mimetype="text/plain" />
        </resource>
      </contentMetadata>
    </publicObject>
    XML
  end
  let(:public_xml_response) { instance_double(HTTP::Response, body: public_xml) }

  before do
    purl_url = 'https://purl.stanford.edu/x.xml'
    allow(described_class.client).to receive(:get).with(purl_url).and_return(public_xml_response)
  end

  describe '#published' do
    it 'parses the published attr out of public XML' do
      expect(object.published).to eq('2021-05-26T23:52:08Z')
    end
  end

  describe '#resources' do
    it 'extracts resources from the contentMetadata' do
      expect(object.resources.map { |file| file['id'] }).to match_array %w[y oversize]
    end
  end

  describe '#ocr_files' do
    it 'has resources that are potentially OCR' do
      expect(object.ocr_files.map { |file| file['id'] }).to include 'y.txt'
    end

    it 'excludes resources that are unlikely to be OCR' do
      expect(object.ocr_files.map { |file| file['id'] }).not_to include 'oversize.txt'
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
      expect(object.to_solr).to include id: 'x/y/y.txt',
                                        druid: 'x',
                                        resource_id: 'y',
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
