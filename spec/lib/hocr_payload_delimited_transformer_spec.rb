# frozen_string_literal: true

require 'spec_helper'
require 'hocr_payload_delimited_transformer'

RSpec.describe HocrPayloadDelimitedTransformer do
  context 'with a hOCR document' do
    subject(:transformer) { described_class.new(File.read('spec/fixtures/example.hocr')) }

    describe '#output' do
      it 'returns a payload-delimited string' do
        expect(transformer.output[0]).to start_with 'REN☞638,108,118,39'
        expect(transformer.output[1]).to start_with 'Reintfelter☞331,188,165,27'
      end

      it 'includes line breaks where appropriate' do
        words_only = transformer.output.map { |block| block.gsub(/☞[\d,\.]+/, '') }
        expect(words_only).to include "Reintfelter Jacob, tailor, 133 Goerck 1 ,\n" \
          "Reinwald Augustus, shoemaker, 23 Spruce\n" \
          "Reirdon Robert, porterhouse, 443 Washington\n" \
          'Reis Anton, painter, 642714 Monroe'
      end
    end
  end
end
