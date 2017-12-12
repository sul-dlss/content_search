# frozen_string_literal: true

require 'spec_helper'
require 'alto_payload_delimited_transformer'

RSpec.describe AltoPayloadDelimitedTransformer do
  subject(:transformer) { described_class.new(File.read('spec/fixtures/bb018zb8894_04_0009.xml')) }

  describe '#output' do
    it 'returns a payload-delimited string' do
      expect(transformer.output.first).to start_with 'George☞639,129,79,243 Stirling’s☞633,426,84,300 Heritage☞632,789,84,291'
    end
  end
end
