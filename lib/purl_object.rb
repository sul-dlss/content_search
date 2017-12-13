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

  def to_solr
    return to_enum(:to_solr) unless block_given?
    resources.each do |r|
      r.xpath('file[@mimetype="application/alto+xml" or @mimetype="text/plain"]').each do |file|
        f = PurlObject::File.new(druid, file)
        yield FullTextIndexer.new(f).to_solr
      end
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
    fetch(format(Settings.purl.public_xml_url, druid: druid))
  end

  # File object within a PURL document
  class File
    attr_reader :druid, :file_xml_fragment

    def initialize(druid, file_xml_fragment)
      @druid = druid
      @file_xml_fragment = file_xml_fragment
    end

    def resource_id
      file_xml_fragment.xpath('..').first.attr('id')
    end

    def filename
      file_xml_fragment.attr('id')
    end

    def mimetype
      file_xml_fragment.attr('mimetype')
    end

    def file_url
      format(Settings.stacks.file_url, druid: druid, filename: filename)
    end

    def content
      fetch(file_url)
    end

    private

    def fetch(url)
      PurlObject.client.get(url).body
    end
  end
end
