require 'alto_payload_delimited_transformer'

class AltoIndexer
  attr_reader :pid, :resource_id, :content

  def initialize(pid, resource_id, content)
    @pid = pid
    @resource_id = resource_id
    @content = content
  end

  def to_solr
    {
      id: "#{pid}/#{resource_id}",
      pid: pid,
      resource_id: resource_id,
      ocrtext: AltoPayloadDelimitedTransformer.new(content).output
    }
  end
end
