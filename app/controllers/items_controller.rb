# frozen_string_literal: true

# Discovery-dispatcher API endpoint for synchronizing the index on changes
class ItemsController < ApplicationController
  def update
    IndexFullTextContentJob.perform_now(params[:druid])
  end

  def destroy
    DeleteContentFromIndexJob.perform_now(params[:druid])
  end
end
