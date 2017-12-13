# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ItemsController do
  describe 'PUT update' do
    it 'kicks off a job' do
      allow(IndexFullTextContentJob).to receive(:perform_now)
      put :update, params: { druid: 'x' }
      expect(IndexFullTextContentJob).to have_received(:perform_now).with('x')
    end
  end

  describe 'DELETE destroy' do
    it 'kicks off a job' do
      allow(DeleteContentFromIndexJob).to receive(:perform_now)
      delete :destroy, params: { druid: 'x' }
      expect(DeleteContentFromIndexJob).to have_received(:perform_now).with('x')
    end
  end
end
