# frozen_string_literal: true

require 'faraday'
require 'full_text_indexer'
require 'purl_object/file'

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

  def ocr_files
    return to_enum(:ocr_files) unless block_given?

    resources.each do |r|
      r.xpath('file[@mimetype="application/xml" or @mimetype="application/alto+xml" or @mimetype="text/plain"]').each do |file|
        yield file unless file['size'].to_i > Settings.maximum_ocr_filesize_to_consider
      end
    end
  end

  def to_solr
    return to_enum(:to_solr) unless block_given?

    ocr_files.each do |file|
      f = PurlObject::File.new(druid, file)

      next if f.content.nil?

      indexer = FullTextIndexer.new(f)

      next if file['mimetype'] == 'application/xml' && !indexer.alto?

      yield indexer.to_solr
    end
  end

  private

  def fetch(url)
    self.class.client.get(url).body
  end

  def public_xml
    Nokogiri::XML.parse(public_xml_body)
  end

  def public_xml_body
    fetch(format(Settings.purl.public_xml_url, druid: druid))
  end
end
