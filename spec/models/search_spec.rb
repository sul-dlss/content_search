# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Search do
  subject(:search) { described_class.new('x', 'y') }

  describe '#highlights' do
    it 'transforms Solr responses into a hash' do
      client = instance_double(RSolr::Client, get: { 'highlighting' => { 'x' => { 'ocrtext' => %w[1 2] } } })
      allow(described_class).to receive(:client).and_return(client)
      expect(search.highlights).to include 'x' => match_array(%w[1 2])
    end
  end
end
