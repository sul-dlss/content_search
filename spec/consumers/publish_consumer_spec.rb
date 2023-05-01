# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PublishConsumer do
  let(:consumer) { described_class.new }

  describe '#process' do
    before do
      allow(Search).to receive(:client).and_return(instance_double(RSolr::Client, delete_by_query: nil))
    end

    let(:message) { instance_double(Racecar::Message, value: message_value) }

    context 'when the message has a value' do
      let(:message_value) { { druid: 'druid:123' }.to_json }
      let(:message) { instance_double(Racecar::Message, value: message_value) }

      before do
        consumer.process(message)
      end

      it 'creates a delete content job' do
        expect(Search.client).to have_received(:delete_by_query).with('druid:123', params: { commit: true })
      end
    end

    context 'when the message value is nil' do
      let(:headers) { { foo: 'bar' } }
      let(:timestamp) { '19990404' }
      let(:offset) { '101010' }
      let(:key) { 'dr712bb2404' }

      let(:message) { instance_double(Racecar::Message, value: nil, key: key, offset: offset, create_time: timestamp, headers: headers) }

      before do
        allow(Honeybadger).to receive(:notify)
        consumer.process(message)
      end

      it 'logs to honeybadger' do
        expect(Honeybadger).to have_received(:notify).with('Blank message received',
                                                           context: { message_headers: headers,
                                                                      message_timestamp: timestamp,
                                                                      message_key: key,
                                                                      message_offset: offset })
      end
    end
  end
end
