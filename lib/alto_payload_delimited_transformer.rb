# frozen_string_literal: true

require 'nokogiri'

# Transform Alto XML to payload-delimited strings for solr
class AltoPayloadDelimitedTransformer
  attr_reader :content, :ns

  def initialize(content)
    @content = content
  end

  def namespaces
    @namespaces ||= begin
      alto_ns = document.namespaces.values.first { |ns| ns =~ %r{standards/alto/ns} }
      { alto: alto_ns || 'http://www.loc.gov/standards/alto/ns-v3#' }
    end
  end

  def text_blocks
    document.xpath('//alto:TextBlock', namespaces)
  end

  def output
    text_blocks.map do |block|
      block.xpath('.//alto:TextLine', namespaces).map do |line|
        line.xpath('.//alto:String', namespaces).map do |el|
          "#{el['CONTENT']}☞#{%w[HPOS VPOS WIDTH HEIGHT].map { |k| el[k] }.join(',')}"
        end.join(' ')
      end.join("\n")
    end
  end

  private

  def document
    Nokogiri::XML.parse(content)
  end
end
