# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PurlObject::File do
  subject(:purl_file) { described_class.new('somedruid', file_metadata, fileset_metadata) }

  let(:file_metadata) { { filename: '92280263.xml', hasMimeType: 'application/xml', size: 46424 }.with_indifferent_access }
  let(:fileset_metadata) { { externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/abc123' }.with_indifferent_access }

  describe '#file_url' do
    context 'with a file with a space' do
      let(:file_metadata) { { filename: 'Read Me', hasMimeType: 'application/xml', size: 46424 }.with_indifferent_access }

      it 'URI escapes the file name' do
        expect(purl_file.file_url).to eq 'https://stacks.stanford.edu/file/somedruid/Read+Me'
      end
    end
  end
end
