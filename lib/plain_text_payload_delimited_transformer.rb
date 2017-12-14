# frozen_string_literal: true

# Transform plain text to payload-delimited strings for solr
class PlainTextPayloadDelimitedTransformer
  attr_reader :content

  def initialize(content)
    @content = content.encode('UTF-8', invalid: :replace, undef: :replace)
  end

  def output
    [content]
  end
end
