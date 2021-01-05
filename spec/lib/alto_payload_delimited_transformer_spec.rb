# frozen_string_literal: true

require 'spec_helper'
require 'alto_payload_delimited_transformer'

RSpec.describe AltoPayloadDelimitedTransformer do
  context 'with an ALTO v2 document' do
    subject(:transformer) { described_class.new(File.read('spec/fixtures/bb018zb8894_04_0009.xml')) }

    describe '#output' do
      it 'returns a payload-delimited string' do
        expect(transformer.output.first).to start_with 'George☞129,639,243,79 Stirling’s☞426,633,300,84 Heritage☞789,632,291,84'
      end
    end
  end

  context 'with an ALTO v3 document' do
    subject(:transformer) { described_class.new(File.read('spec/fixtures/EastTimor_Report_of_the_UNSG_2006_0001.xml')) }

    describe '#output' do
      it 'returns a payload-delimited string' do
        expect(transformer.output.first).to start_with 'United☞514.00,229.00,147.43,42.00 Nations☞686.00,229.00,172.00,42.00'
      end

      it 'includes line breaks where appropriate' do
        words_only = transformer.output.map { |block| block.gsub(/☞[\d,.]+/, '') }
        expect(words_only).to include "Progress report of the Secretary-General on the\nUnited Nations Office in Timor-Leste"
      end
    end
  end
end
