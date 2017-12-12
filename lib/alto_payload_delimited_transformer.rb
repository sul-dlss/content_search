require 'nokogiri'

class AltoPayloadDelimitedTransformer
  attr_reader :content

  def initialize(content)
    @content = content
  end

  # TODO: escape pipes in the content
  def output
    document.xpath('//alto:String', alto: 'http://www.loc.gov/standards/alto/ns-v2#').map do |el|
      "#{el['CONTENT']}☞#{['VPOS', 'HPOS', 'HEIGHT', 'WIDTH'].map { |k| el[k] }.join(',')}"
    end.join(' ')
  end

  private

  def document
    Nokogiri::XML.parse(content)
  end
end
