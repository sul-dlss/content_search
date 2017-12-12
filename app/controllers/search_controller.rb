# frozen_string_literal: true

class SearchController < ApplicationController #:nodoc:
  def search
    @search = Search.new(search_params)

    respond_to do
      format.json { render json: IiifContentSearchResponse.new(@search, current_url) }
    end
  end

  private

  def search_params
    params.permit(:id)
    params.permit(:q)
  end
end
