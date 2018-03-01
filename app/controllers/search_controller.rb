# frozen_string_literal: true

class SearchController < ApplicationController #:nodoc:
  before_action :load_search, except: [:home]

  def home
    head :ok
  end

  def search
    response.headers['Access-Control-Allow-Origin'] = '*'
    render json: IiifContentSearchResponse.new(@search, self)
  end

  def autocomplete
    response.headers['Access-Control-Allow-Origin'] = '*'
    render json: IiifAutocompleteResponse.new(@search, self)
  end

  private

  def load_search
    @search = Search.new(search_params[:id], search_params.slice(:q, :start).to_h.symbolize_keys)
  end

  def search_params
    params.require(:q)
    params.permit(:id, :q, :start)
  end
end
