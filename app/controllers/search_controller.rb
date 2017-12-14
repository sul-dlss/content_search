# frozen_string_literal: true

class SearchController < ApplicationController #:nodoc:
  def search
    @search = Search.new(params[:id], params[:q])

    response.headers['Access-Control-Allow-Origin'] = '*'
    render json: IiifContentSearchResponse.new(@search, request.original_url)
  end

  private

  def search_params
    params.permit(:id, :q)
  end
end