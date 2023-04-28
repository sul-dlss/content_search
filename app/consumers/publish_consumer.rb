# frozen_string_literal: true

# Harvest changed content from kafka
class PublishConsumer < Racecar::Consumer
  subscribes_to Settings.kafka.topic
  # Set group_id differently in prod and uat, so they can both receive the message
  self.group_id = Settings.kafka.group_id

  def process(message)
    if message.value.nil?
      Honeybadger.notify('Blank message received',
                         context: { message_offset: message.offset,
                                    message_headers: message.headers,
                                    message_timestamp: message.create_time })
      return
    end

    data = JSON.parse(message.value)

    Search.client.delete_by_query("druid:#{data['druid'].delete_prefix('druid:')}", params: { commit: true })
  rescue StandardError => e
    Honeybadger.notify(e)
    raise e
  end
end
