# frozen_string_literal: true

require 'http'
require 'full_text_indexer'
require 'purl_object/file'
require 'parallel'

# Wrapper for objects in PURL
class PurlObject
  def self.client
    HTTP
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
      r.xpath('file[@role="transcription"][@mimetype="application/xml" or @mimetype="application/alto+xml" or @mimetype="text/plain"]').each do |file|
        yield file unless file['size'].to_i > Settings.maximum_ocr_filesize_to_consider
      end
    end
  end

  def to_solr(options = { in_threads: 8 })
    return to_enum(:to_solr, options) unless block_given?

    # Inject "bookkeeping" document into index first to record last published date
    yield({ id: druid, druid: druid, published: published, resource_id: 'druid' })

    results = Parallel.map(ocr_files, options) do |file|
      PurlObject::File.new(druid, file).to_solr
    end

    # preserving the stream-like API for now..
    results.each { |r| yield r unless r.nil? }
  end

  def published
    public_xml.root['published']
  end

  private

  def fetch(url)
    self.class.client.get(url).body.to_s
  end

  def public_xml
    @public_xml ||= Nokogiri::XML.parse(public_xml_body)
  end

  def public_xml_body
    fetch(format(Settings.purl.public_xml_url, druid: druid))
  end
end
