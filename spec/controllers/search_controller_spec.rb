# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SearchController do
  let(:search) do
    instance_double(Search, id: 'x',
                            num_found: 10,
                            rows: 10,
                            start: 0,
                            highlights: { 'x/y/z' => ['some <em>highlighted</em> text'] })
  end

  describe 'GET home' do
    it 'is a success' do
      get :home
      expect(response).to be_successful
    end
  end

  describe 'GET search' do
    before do
      allow(Search).to receive(:new).with('x', q: 'y').and_return(search)
    end

    context 'without required parameters' do
      it 'renders a 400 Bad Request error' do
        expect do
          get :search, params: { id: 'x' }
        end.to raise_exception ActionController::ParameterMissing
      end
    end

    it 'executes a search and transforms it into a content search response' do
      get :search, params: { id: 'x', q: 'y', motivation: 'painting' }

      data = response.parsed_body

      expect(data).to include '@context' => ['http://iiif.io/api/presentation/2/context.json',
                                             'http://iiif.io/api/search/1/context.json'],
                              '@id' => 'http://test.host/x/search?motivation=painting&q=y',
                              '@type' => 'sc:AnnotationList',
                              'within' => include('ignored' => ['motivation'])
    end

    it 'includes resources for every hit' do
      get :search, params: { id: 'x', q: 'y' }

      data = response.parsed_body

      expect(data['resources']).to include '@id' => 'https://purl.stanford.edu/x/iiif/canvas/y/text/at/0,0,0,0',
                                           '@type' => 'oa:Annotation',
                                           'motivation' => 'sc:painting',
                                           'resource' => {
                                             '@type' => 'cnt:ContentAsText',
                                             'chars' => 'highlighted'
                                           },
                                           'on' => 'https://purl.stanford.edu/x/iiif/canvas/y#xywh=0,0,0,0'
    end
  end
end
