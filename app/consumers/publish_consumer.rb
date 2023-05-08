# frozen_string_literal: true

# Harvest changed content from kafka
class PublishConsumer < Racecar::Consumer
  subscribes_to Settings.kafka.topic
  # Set group_id differently in prod and uat, so they can both receive the message
  self.group_id = Settings.kafka.group_id

  # Remove the solr document based on the message key.  The solr index is just acting as a cache
  # which is cleared when we receive a message. The cache is rebuild when someone tries to access
  # a document that doesn't exist in solr.
  #
  # The message key contains the prefixed druid.
  # If the message.value is nil, then a publish event happend with dark access.
  def process(message)
    druid = message.key.delete_prefix('druid:')
    Search.client.delete_by_query("druid:#{druid}", params: { commit: true })
  rescue StandardError => e
    Honeybadger.notify(e)
    raise e
  end
end
