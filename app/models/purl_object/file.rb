# frozen_string_literal: true

class PurlObject
  # File object within a PURL document
  class File
    attr_reader :druid, :file_metadata, :fileset_metadata

    def self.client
      Thread.current[:client] ||= HTTP.persistent(Settings.stacks.host)
    end

    def initialize(druid, file_metadata, fileset_metadata = {})
      @druid = druid
      @file_metadata = file_metadata
      @fileset_metadata = fileset_metadata
    end

    def resource_id
      fileset_metadata['externalIdentifier']&.sub('https://cocina.sul.stanford.edu/fileSet/', 'cocina-fileSet-')
    end

    def filename
      file_metadata['filename']
    end

    def mimetype
      file_metadata['hasMimeType']
    end

    def file_url
      format(Settings.stacks.file_url, druid: druid, filename: CGI.escape(filename))
    end

    def content
      fetch(file_url)
    end

    def to_solr
      return if content.nil?

      indexer = FullTextIndexer.new(self)

      return if mimetype == 'application/xml' && !indexer.alto?

      indexer.to_solr
    end

    private

    def fetch(url)
      response = PurlObject::File.client.get(url)
      response.body.to_s if response.status.success?
    end
  end
end
