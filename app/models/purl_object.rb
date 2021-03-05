# frozen_string_literal: true

require 'http'
require 'full_text_indexer'
require 'purl_object/file'
require 'parallel'

# Wrapper for objects in PURL
class PurlObject
  attr_reader :druid

  def initialize(druid)
    @druid = druid
  end

  def public_xml_record
    @public_xml_record ||= PurlFetcher::Client::PublicXmlRecord.new(druid, purl_url: format(Settings.purl.public_xml_url, druid: ''))
  end

  delegate :public_xml_doc, to: :public_xml_record

  def resources
    public_xml_doc.xpath('//contentMetadata/resource')
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

    results = Parallel.map(ocr_files, options) do |file|
      PurlObject::File.new(druid, file).to_solr
    end

    # preserving the stream-like API for now..
    results.each { |r| yield r unless r.nil? }
  end
end
