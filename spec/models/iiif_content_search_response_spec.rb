# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IiifContentSearchResponse do
  subject(:response) { described_class.new(search, 'http://example.com') }

  let(:search) { instance_double(Search, highlights: highlights) }
  let(:highlights) do
    {
      'x/y/alto_with_coords' => ['<em>George☞639,129,79,243 Stirling’s☞633,426,84,300</em> Heritage☞632,789,84,291'],
      'x/y/text_without_coords' => ['<em>MEMBERS</em> OF THE COUNCIL']
    }
  end

  describe '#as_json' do
    it 'has the expected json-ld properties' do
      expect(response.as_json).to include "@context": 'http://iiif.io/api/presentation/2/context.json',
                                          "@id": 'http://example.com',
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
  end
end
