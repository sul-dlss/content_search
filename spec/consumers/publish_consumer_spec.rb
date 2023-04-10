# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PublishConsumer do
  let(:consumer) { described_class.new }

  describe '#process' do
    before do
      allow(Search).to receive(:client).and_return(instance_double(RSolr::Client, delete_by_query: nil))
      consumer.process(message)
    end

    let(:message) { instance_double(Racecar::Message, value: message_value) }
    let(:message_value) { { druid: 'druid:123' }.to_json }

    it 'creates a delete content job' do
      expect(Search.client).to have_received(:delete_by_query).with('druid:druid:123', params: { commit: true })
    end
  end
end
