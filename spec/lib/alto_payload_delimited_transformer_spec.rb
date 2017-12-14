# frozen_string_literal: true

require 'spec_helper'
require 'alto_payload_delimited_transformer'

RSpec.describe AltoPayloadDelimitedTransformer do
  subject(:transformer) { described_class.new(File.read('spec/fixtures/bb018zb8894_04_0009.xml')) }

  describe '#output' do
    it 'returns a payload-delimited string' do
      expect(transformer.output.first).to start_with 'George☞129,639,243,79 Stirling’s☞426,633,300,84 Heritage☞789,632,291,84'
    end
  end
end
