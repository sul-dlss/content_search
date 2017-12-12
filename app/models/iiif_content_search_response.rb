# frozen_string_literal: true

# Transforming search highlighting results into IIIF Content Search API responses
class IiifContentSearchResponse
  attr_reader :search, :url

  def initialize(search, url)
    @search = search
    @url = url
  end

  def as_json
    {
      "@context": 'http://iiif.io/api/presentation/2/context.json',
      "@id": url,
      "@type": 'sc:AnnotationList',
      "resources": resources.map(&:as_json)
    }
  end

  private

  def resources
    return to_enum(:resources) unless block_given?

    search.highlights.each do |id, hits|
      hits.each do |hit|
        yield Resource.new(id, hit)
      end
    end
  end

  # Transform individual search highlights into IIIF resource annotations
  class Resource
    attr_reader :id, :highlight

    def initialize(id, highlight)
      @id = id
      @highlight = highlight
    end

    def as_json
      {
        "@id": annotation_url,
        "@type": 'oa:Annotation',
        "motivation": 'sc:painting',
        "resource": {
          "@type": 'cnt:ContentAsText',
          "chars": chars
        },
        "on": canvas_fragment_url
      }
    end

    private

    def druid
      id.split('/', 2).first
    end

    def resource_id
      id.split('/', 2).last
    end

    def annotation_url
      "#{canvas_url}/text/at/#{fragment_xywh}"
    end

    def text
      first = highlight.index('<em>')
      last = highlight.rindex('</em>')
      highlight[first...last].gsub(%r{</?em>}, '')
    end

    def chars
      text.split.map { |x| x.split('☞') }.map(&:first).join(' ')
    end

    def word_bboxes
      @word_bboxes ||= begin
        text.split.map { |x| x.split('☞') }.map(&:last).compact.map do |xywh|
          x, y, w, h = xywh.split(',').map(&:to_i)
          [[x, y], [x + w, y + h]]
        end
      end
    end

    def bbox
      @bbox ||= begin
        pos1s = word_bboxes.map(&:first)
        pos2s = word_bboxes.map(&:last)
        {
          x1: pos1s.map(&:first).min,
          y1: pos1s.map(&:last).min,
          x2: pos2s.map(&:first).max,
          y2: pos2s.map(&:last).max
        }
      end
    end

    def fragment_xywh
      [bbox[:x1], bbox[:y1], bbox[:x2] - bbox[:x1], bbox[:y2] - bbox[:y1]].join(',')
    end

    def canvas_fragment_url
      "#{canvas_url}#xywh=#{fragment_xywh}"
    end

    def canvas_url
      format(Settings.purl.canvas_url, druid: druid, resource: resource_id)
    end
  end
end
