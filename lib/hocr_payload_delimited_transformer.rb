# frozen_string_literal: true

require 'nokogiri'

# Transform Alto XML to payload-delimited strings for solr
class HocrPayloadDelimitedTransformer
  attr_reader :content, :ns

  def initialize(content)
    @content = content
  end

  def text_blocks
    document.css('.ocr_par')
  end

  def output
    text_blocks.map do |block|
      block.css('.ocr_line').map do |line|
        line.css('.ocrx_word').map do |el|
          extract_word(el)
        end.join(' ')
      end.join("\n")
    end
  end

  private

  def document
    Nokogiri::HTML.parse(content)
  end

  def extract_word(word_el)
    metadata = (word_el.attr('title').split(';')&.map { |x| x.strip.split(' ', 2) } || []).to_h

    x0, y0, x1, y1 = extract_bbox(metadata['bbox'])

    "#{word_el.text}☞#{x0},#{y0},#{x1 - x0},#{y1 - y0}"
  end

  def extract_bbox(bbox)
    return [0, 0, 0, 0] unless bbox

    x0, y0, x1, y1 = bbox.split(' ')&.map(&:to_i)

    [x0 || 0, y0 || 0, x1 || 0, y1 || 0]
  end
end
