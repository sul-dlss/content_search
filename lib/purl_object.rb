# frozen_string_literal: true

require 'faraday'
require 'full_text_indexer'

# Wrapper for objects in PURL
class PurlObject
  def self.client
    Faraday
  end

  attr_reader :druid

  def initialize(druid)
    @druid = druid
  end

  def resources
    public_xml.xpath('//contentMetadata/resource')
  end

  def ocr_resources
    resources.select { |r| r.xpath('file[@mimetype="application/alto+xml"]') }
  end

  def to_solr
    ocr_resources.map do |r|
      resource_id = r['id']
      filename = r.xpath('file[@mimetype="application/alto+xml"]').first&.attr('id')
      ocr_url = format(Settings.stacks.file_url, druid: druid, filename: filename)
      FullTextIndexer.new(druid, resource_id, fetch(ocr_url)).to_solr
    end
  end

  def fetch(url)
    self.class.client.get(url).body
  end

  private

  def public_xml
    Nokogiri::XML.parse(public_xml_body)
  end

  def public_xml_body
    self.class.client.get(format(Settings.purl.public_xml_url, druid: druid)).body
  end
end
