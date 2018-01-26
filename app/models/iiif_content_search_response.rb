# frozen_string_literal: true

# Transforming search highlighting results into IIIF Content Search API responses
class IiifContentSearchResponse
  attr_reader :search, :controller

  delegate :request, to: :controller

  def initialize(search, controller)
    @search = search
    @controller = controller
  end

  def as_json(*_args)
    {
      "@context": [
        'http://iiif.io/api/presentation/2/context.json',
        'http://iiif.io/api/search/1/context.json'
      ],
      "@id": request.original_url,
      "@type": 'sc:AnnotationList',
      "resources": resources.map(&:as_json),
      "hits": hits
    }.merge(pagination_as_json)
  end

  def resources
    return to_enum(:resources) unless block_given?

    search.highlights.each do |id, hits|
      hits.each do |hit|
        yield Resource.new(id, hit)
      end
    end
  end

  private

  def pagination_as_json
    hash = {
      within: {
        '@type': 'sc:Layer',
        first: first_page_url,
        last: last_page_url,
        ignored: ignored_params
      }
    }
    hash[:next] = next_page_url if next_page?
    hash
  end

  def first_page_url
    controller.iiif_content_search_url(id: search.id, start: 0)
  end

  def next_page_url
    controller.iiif_content_search_url(id: search.id, start: search.start + search.rows)
  end

  def last_page_url
    start = 0 if search.num_found <= search.rows
    start ||= last_page
    controller.iiif_content_search_url(id: search.id, start: start)
  end

  def last_page
    search.num_found - (search.num_found % search.rows)
  end

  def next_page?
    search.num_found >= (search.start + search.rows)
  end

  def ignored_params
    Settings.iiif.ignored_request_params.select { |param| controller.params.keys.include?(param) }
  end

  def hits
    resources.map do |hit|
      {
        '@type': 'search:Hit',
        'annotations': [hit.annotation_url],
        'before': hit.before,
        'after': hit.after
      }
    end
  end

  # Transform individual search highlights into IIIF resource annotations
  class Resource
    attr_reader :druid, :resource_id, :filename, :highlight

    def initialize(id, highlight)
      @druid, @resource_id, @filename = id.split('/')
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

    def annotation_url
      "#{canvas_url}/text/at/#{fragment_xywh}"
    end

    def text
      first = highlight.index('<em>')
      last = highlight.rindex('</em>')
      highlight[first...last].gsub(%r{</?em>}, '')
    end

    def before
      first = highlight.index('<em>')
      tokenized_text(highlight[0...first]).map(&:first).join(' ').strip
    end

    def after
      token = '</em>'
      last = highlight.rindex(token) + token.length
      tokenized_text(highlight[last..highlight.length]).map(&:first).join(' ').strip
    end

    private

    def chars
      tokenized_text(text).map(&:first).join(' ')
    end

    def word_bboxes
      @word_bboxes ||= begin
        tokenized_text(text).map(&:last).compact.map do |xywh|
          x, y, w, h = xywh.split(',').map(&:to_i)
          [[x, y], [x + w, y + h]]
        end
      end
    end

    def split_word_and_payload(x)
      if x.match?(/☞/)
        x.split('☞')
      else
        [x, '0,0,0,0']
      end
    end

    def bbox
      @bbox ||= begin
        pos1s = word_bboxes.map(&:first)
        pos2s = word_bboxes.map(&:last)
        {
          x1: [pos1s.map(&:first).min, pos2s.map(&:first).min].min,
          y1: [pos1s.map(&:last).min, pos2s.map(&:last).min].min,
          x2: [pos1s.map(&:first).max, pos2s.map(&:first).max].max,
          y2: [pos1s.map(&:last).max, pos2s.map(&:last).max].max
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

    def tokenized_text(text)
      sanitized_text(text).split.map { |x| split_word_and_payload(x) }
    end

    def sanitized_text(text)
      return text unless text.match?(/☞/)

      text.sub(/^[\d+,\.]+ /, '')
    end
  end
end
