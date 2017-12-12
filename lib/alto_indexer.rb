require 'alto_payload_delimited_transformer'

class AltoIndexer
  attr_reader :druid, :resource_id, :content

  def initialize(druid, resource_id, content)
    @druid = druid
    @resource_id = resource_id
    @content = content
  end

  def to_solr
    {
      id: "#{druid}/#{resource_id}",
      druid: druid,
      resource_id: resource_id,
      ocrtext: AltoPayloadDelimitedTransformer.new(content).output
    }
  end
end
