# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PurlObject::File do
  subject(:purl_file) { described_class.new('somedruid', file_xml_fragment) }

  let(:file_xml_fragment) { Nokogiri::XML.parse(xml).root }
  let(:xml) { '<file id="92280263.xml" mimetype="application/xml" size="46424"></file>' }

  describe '#file_url' do
    context 'with a file with a space' do
      let(:xml) { '<file id="Read Me" mimetype="application/xml" size="46424"></file>' }

      it 'URI escapes the file name' do
        expect(purl_file.file_url).to eq 'https://stacks.stanford.edu/file/somedruid/Read+Me'
      end
    end
  end
end
