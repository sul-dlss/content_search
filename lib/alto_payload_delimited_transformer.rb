# frozen_string_literal: true

require 'nokogiri'

# Transform Alto XML to payload-delimited strings for solr
class AltoPayloadDelimitedTransformer
  attr_reader :content, :ns

  def initialize(content)
    @content = content
  end

  def namespaces
    @namespaces ||= { alto: 'http://www.loc.gov/standards/alto/ns-v2#' }
  end

  def text_blocks
    document.xpath('//alto:TextBlock', namespaces)
  end

  def output
    text_blocks.map do |block|
      block.xpath('.//alto:String', namespaces).map do |el|
        "#{el['CONTENT']}☞#{%w[HPOS VPOS WIDTH HEIGHT].map { |k| el[k] }.join(',')}"
      end.join(' ')
    end
  end

  private

  def document
    Nokogiri::XML.parse(content)
  end
end
