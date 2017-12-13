# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Discovery dispatcher routes' do
  it 'routes to #update' do
    expect(put: '/items/x/subtargets/abc').to route_to('items#update', druid: 'x', subtargets: 'subtargets/abc')
  end

  it 'routes the root url' do
    expect(delete: '/items/x/subtargets/abc').to route_to('items#destroy', druid: 'x', subtargets: 'subtargets/abc')
  end
end
