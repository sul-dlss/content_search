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
      "resources": resources.flat_map(&:annotations),
      "hits": hits
    }.merge(pagination_as_json)
  end

  def resources
    return to_enum(:resources) unless block_given?

    search.highlights.each do |id, hits|
      # Hit here refers to the Solr hit
      hits.each do |hit|
        hit.gsub('</em> <em>', ' ').to_enum(:scan, %r{<em>.*?</em>}).each do |*_match|
          yield Resource.new(id, Regexp.last_match)
        end
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
    Settings.iiif.ignored_request_params.select { |param| controller.params.key?(param) }
  end

  def hits
    resources.map do |hit|
      {
        '@type': 'search:Hit',
        'annotations': hit.annotation_urls,
        'before': hit.before,
        'after': hit.after,
        'match': hit.match
      }
    end
  end

  # Transform individual search highlights into IIIF resource annotations
  class Resource
    attr_reader :druid, :resource_id, :filename, :highlight, :pre_match, :post_match

    def initialize(id, highlight)
      @druid, @resource_id, @filename = id.split('/')
      @highlight = strip_em highlight.to_s
      @pre_match = strip_em highlight.pre_match
      @post_match = strip_em highlight.post_match
    end

    def annotations
      tokens.map do |(chars, xywh)|
        {
          "@id": annotation_url([chars, xywh]),
          "@type": 'oa:Annotation',
          "motivation": 'sc:painting',
          "resource": {
            "@type": 'cnt:ContentAsText',
            "chars": chars
          },
          "on": canvas_fragment_url(xywh)
        }
      end
    end

    def annotation_urls
      tokens.map do |(chars, xywh)|
        annotation_url([chars, xywh])
      end
    end

    def annotation_url(token)
      "#{canvas_url}/text/at/#{token.last}"
    end

    def before
      tokenized_text(pre_match).map(&:first).join(' ').strip
    end

    def after
      tokenized_text(post_match).map(&:first).join(' ').strip
    end

    def match
      tokenized_text(highlight).map(&:first).join(' ').strip
    end

    private

    def tokens
      highlight.split.map { |x| split_word_and_payload(x) }
    end

    def split_word_and_payload(x)
      if x.match?(/☞/)
        x.split('☞')
      else
        [x, '0,0,0,0']
      end
    end

    def canvas_fragment_url(xywh)
      "#{canvas_url}#xywh=#{xywh.split(',').map(&:to_i).join(',')}"
    end

    def canvas_url
      format(Settings.purl.canvas_url, druid: druid, resource: resource_id)
    end

    def tokenized_text(text)
      sanitized_text(text).split.map { |x| split_word_and_payload(x) }
    end

    def strip_em(text)
      text.gsub(%r{</?em>}, '')
    end

    def sanitized_text(text)
      return text unless text.match?(/☞/)

      text.sub(/^[\d+,\.]+ /, '')
    end
  end
end
