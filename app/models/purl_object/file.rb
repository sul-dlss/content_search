# frozen_string_literal: true

class PurlObject
  # File object within a PURL document
  class File
    attr_reader :druid, :file_xml_fragment

    def self.client
      Thread.current[:client] ||= HTTP.persistent(Settings.stacks.host)
    end

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
