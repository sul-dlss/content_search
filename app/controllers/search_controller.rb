# frozen_string_literal: true

class SearchController < ApplicationController #:nodoc:
  def search
    @search = Search.new(search_params[:id], search_params.slice(:q, :start).to_h.symbolize_keys)

    response.headers['Access-Control-Allow-Origin'] = '*'
    render json: IiifContentSearchResponse.new(@search, self)
  end

  private

  def search_params
    params.permit(:id, :q, :start)
  end
end
