# frozen_string_literal: true

require 'spec_helper'
require 'full_text_indexer'
require 'purl_object'

RSpec.describe FullTextIndexer do
  subject(:indexer) { described_class.new(file) }

  let(:file) do
    instance_double(PurlObject::File, druid: 'x',
                                      resource_id: 'y',
                                      filename: 'z',
                                      mimetype: 'application/xml',
                                      content: File.read('spec/fixtures/bb018zb8894_04_0009.xml'))
  end

  describe '#to_solr' do
    it 'creates a solr document for indexing' do
      expect(indexer.to_solr).to include id: 'x/y/z',
                                         druid: 'x',
                                         resource_id: 'y',
                                         filename: 'z',
                                         ocrtext: include(start_with('George'))
    end
  end

  describe '#alto?' do
    it 'checks if the content looks like ALTO xml' do
      expect(indexer.alto?).to be true
    end
  end

  context 'with a plain text file' do
    let(:file) do
      instance_double(PurlObject::File, druid: 'x',
                                        resource_id: 'y',
                                        filename: 'z',
                                        mimetype: 'text/plain',
                                        content: File.read('spec/fixtures/00003167_0003.txt'))
    end

    describe '#to_solr' do
      it 'creates a solr document for indexing' do
        expect(indexer.to_solr).to include id: 'x/y/z',
                                           druid: 'x',
                                           resource_id: 'y',
                                           filename: 'z',
                                           ocrtext: include(start_with('MEMBERS OF THE COUNCIL'))
      end
    end

    describe '#alto?' do
      it 'checks if the content looks like ALTO xml' do
        expect(indexer.alto?).to be false
      end
    end
  end
end
