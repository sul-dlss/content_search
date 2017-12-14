# frozen_string_literal: true

require 'alto_payload_delimited_transformer'
require 'plain_text_payload_delimited_transformer'

require 'active_support/core_ext/module/delegation'
# Index full text documents for full-text hit highlighting
class FullTextIndexer
  attr_reader :file

  delegate :druid, :resource_id, :filename, :content, :mimetype, to: :file

  def initialize(file)
    @file = file
  end

  def to_solr
    {
      id: "#{druid}/#{resource_id}/#{filename}",
      druid: druid,
      resource_id: resource_id,
      filename: filename,
      ocrtext: ocr_text_transformer.output
    }
  end

  def alto?
    content.match?(/<alto/)
  end

  private

  def ocr_text_transformer
    case mimetype
    when 'application/xml', 'application/alto+xml'
      AltoPayloadDelimitedTransformer.new(content)
    when 'text/plain'
      PlainTextPayloadDelimitedTransformer.new(content)
    end
  end
end
