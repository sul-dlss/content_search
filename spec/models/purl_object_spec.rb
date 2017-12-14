# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PurlObject do
  subject(:object) { described_class.new('x') }

  let(:public_xml) do
    <<-XML
    <publicObject>
      <contentMetadata>
        <resource id="y">
          <file id="y.txt" mimetype="text/plain" />
        </resource>
      </contentMetadata>
    </publicObject>
    XML
  end
  let(:public_xml_response) { instance_double(Faraday::Response, body: public_xml) }

  before do
    purl_url = 'https://purl.stanford.edu/x.xml'
    allow(described_class.client).to receive(:get).with(purl_url).and_return(public_xml_response)
  end

  describe '#resources' do
    it 'extracts resources from the contentMetadata' do
      expect(object.resources.first['id']).to eq 'y'
    end
  end

  describe '#to_solr' do
    let(:ocr_text) { 'text text text' }
    let(:ocr_response) { instance_double(Faraday::Response, body: ocr_text) }

    before do
      stacks_url = 'https://stacks.stanford.edu/file/x/y.txt'
      allow(described_class.client).to receive(:get).with(stacks_url).and_return(ocr_response)
    end

    it 'creates an indexable hash of OCR content' do
      expect(object.to_solr.first).to include id: 'x/y/y.txt',
                                              druid: 'x',
                                              resource_id: 'y',
                                              filename: 'y.txt',
                                              ocrtext: ['text text text']
    end
  end
end
