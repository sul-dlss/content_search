# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IiifContentSearchResponse, type: :controller do
  controller(SearchController) {}

  subject(:response) { described_class.new(search, controller) }

  let(:search) { instance_double(Search, id: 'x', highlights: highlights, num_found: 10, start: 0, rows: 10) }
  let(:highlights) do
    {
      'x/y/alto_with_coords' => ['<em>George☞639,129,79,243 Stirling’s☞633,426,84,300</em> Heritage☞632,789,84,291'],
      'x/y/alto_multiline_coords' => ['<em>George☞639,129,79,243 Stirling’s☞732,0,84,291</em>'],
      'x/y/text_without_coords' => ['<em>MEMBERS</em> OF THE COUNCIL']
    }
  end

  describe '#before' do
    context 'with truncated coordinate payloads in the highlight' do
      let(:highlights) do
        {
          'x/truncated_highlight_coords/alto' => ['0,2 George☞639,129,79,243 <em>Stirling’s☞633,426,84,300</em>']
        }
      end

      it 'strips leading payload fragments' do
        expect(response.resources.first.before).to eq 'George'
      end
    end
  end

  describe '#as_json' do
    it 'has the expected json-ld properties' do
      expect(response.as_json).to include "@context": ['http://iiif.io/api/presentation/2/context.json',
                                                       'http://iiif.io/api/search/1/context.json'],
                                          "@id": 'http://test.host',
                                          "@type": 'sc:AnnotationList'
    end

    it 'has a resource for the alto highlight' do
      expect(response.as_json).to include resources: include("@id": 'https://purl.stanford.edu/x/iiif/canvas/y/text/at/633,129,85,597',
                                                             "@type": 'oa:Annotation',
                                                             "motivation": 'sc:painting',
                                                             "resource": {
                                                               "@type": 'cnt:ContentAsText',
                                                               "chars": 'George Stirling’s'
                                                             },
                                                             "on": 'https://purl.stanford.edu/x/iiif/canvas/y#xywh=633,129,85,597')
    end

    it 'highlights the whole matching region for multi-line matches' do
      expect(response.as_json).to include resources: include("@id": 'https://purl.stanford.edu/x/iiif/canvas/y/text/at/639,0,177,372',
                                                             "@type": 'oa:Annotation',
                                                             "motivation": 'sc:painting',
                                                             "resource": {
                                                               "@type": 'cnt:ContentAsText',
                                                               "chars": 'George Stirling’s'
                                                             },
                                                             "on": 'https://purl.stanford.edu/x/iiif/canvas/y#xywh=639,0,177,372')
    end

    it 'has a resource for the plain text highlight' do
      expect(response.as_json).to include resources: include("@id": 'https://purl.stanford.edu/x/iiif/canvas/y/text/at/0,0,0,0',
                                                             "@type": 'oa:Annotation',
                                                             "motivation": 'sc:painting',
                                                             "resource": {
                                                               "@type": 'cnt:ContentAsText',
                                                               "chars": 'MEMBERS'
                                                             },
                                                             "on": 'https://purl.stanford.edu/x/iiif/canvas/y#xywh=0,0,0,0')
    end

    it 'has hits with additional context for an ALTO resource' do
      expect(response.as_json).to include hits: include("@type": 'search:Hit',
                                                        "annotations": [
                                                          'https://purl.stanford.edu/x/iiif/canvas/y/text/at/633,129,85,597'
                                                        ],
                                                        "before": '',
                                                        "after": 'Heritage')
    end

    it 'has hits with additional context for a plain text resource' do
      expect(response.as_json).to include hits: include("@type": 'search:Hit',
                                                        "annotations": [
                                                          'https://purl.stanford.edu/x/iiif/canvas/y/text/at/0,0,0,0'
                                                        ],
                                                        "before": '',
                                                        "after": 'OF THE COUNCIL')
    end

    it 'has basic pagination context' do
      expect(response.as_json).to include within: include('@type': 'sc:Layer',
                                                          first: ending_with('start=0'),
                                                          last: ending_with('start=0'))
    end

    context 'with a next page' do
      let(:search) { instance_double(Search, id: 'x', highlights: highlights, num_found: 17, start: 0, rows: 10) }

      it 'has pagination context' do
        expect(response.as_json).to include next: ending_with('start=10'),
                                            within: include('@type': 'sc:Layer',
                                                            first: ending_with('start=0'),
                                                            last: ending_with('start=10'))
      end
    end

    context 'with a start offset' do
      let(:search) { instance_double(Search, id: 'x', highlights: highlights, num_found: 17, start: 10, rows: 10) }

      it 'has pagination context' do
        expect(response.as_json).to include within: include('@type': 'sc:Layer',
                                                            first: ending_with('start=0'),
                                                            last: ending_with('start=10'))
      end
    end
  end
end
