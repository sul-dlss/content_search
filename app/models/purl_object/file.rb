# frozen_string_literal: true

class PurlObject
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
      format(Settings.stacks.file_url, druid: druid, filename: CGI.escape(filename))
    end

    def content
      fetch(file_url)
    end

    private

    def fetch(url)
      response = PurlObject.client.get(url)

      response.body if response.success?
    end
  end
end
