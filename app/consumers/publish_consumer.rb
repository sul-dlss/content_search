# frozen_string_literal: true

# Harvest changed content from kafka
class PublishConsumer < Racecar::Consumer
  subscribes_to Settings.kafka.topic
  # Set group_id differently in prod and uat, so they can both receive the message
  self.group_id = Settings.kafka.group_id

  def process(message)
    data = JSON.parse(message.value)

    Search.client.delete_by_query("druid:#{data['druid']}", params: { commit: true })
  end
end
