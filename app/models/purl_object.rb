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

  def ocr_files
    return to_enum(:ocr_files) unless block_given?

    resource_files.each do |file, file_set|
      next unless file['use'] == 'transcription'
      next unless file['hasMimeType'].in?(['application/xml', 'application/alto+xml', 'text/plain'])
      next unless file['size'].to_i <= Settings.maximum_ocr_filesize_to_consider

      yield PurlObject::File.new(druid, file, file_set.except('structural'))
    end
  end

  def to_solr(options = { in_threads: 8 })
    return to_enum(:to_solr, options) unless block_given?

    # Inject "bookkeeping" document into index first to record last published date
    yield({ id: druid, druid: druid, published: published, resource_id: 'druid' })

    results = Parallel.map(ocr_files, options, &:to_solr)

    # preserving the stream-like API for now..
    results.each { |r| yield r unless r.nil? }
  end

  def published
    public_cocina['modified']
  end

  private

  def fetch(url)
    self.class.client.get(url).body.to_s
  end

  def public_cocina
    @public_cocina ||= JSON.parse(public_cocina_body)
  end

  def public_cocina_body
    fetch(format(Settings.purl.public_cocina_url, druid: druid))
  end

  def resource_files
    return to_enum(:resource_files) unless block_given?

    public_cocina.dig('structural', 'contains')&.each do |file_set|
      file_set.dig('structural', 'contains').each do |file|
        next unless file.dig('administrative', 'shelve')

        yield file, file_set
      end
    end
  end
end
