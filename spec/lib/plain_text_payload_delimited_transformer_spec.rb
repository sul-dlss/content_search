# frozen_string_literal: true

require 'spec_helper'
require 'plain_text_payload_delimited_transformer'

RSpec.describe PlainTextPayloadDelimitedTransformer do
  subject(:transformer) { described_class.new(File.read('spec/fixtures/00003167_0003.txt')) }

  describe '#output' do
    it 'returns a payload-delimited string' do
      expect(transformer.output.first).to start_with 'MEMBERS OF THE COUNCIL'
    end
  end
end
