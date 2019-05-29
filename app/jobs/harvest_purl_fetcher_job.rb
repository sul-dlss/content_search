# frozen_string_literal: true

# Harvest changed content from purl-fetcher
class HarvestPurlFetcherJob < ApplicationJob
  STATE_FILE = Rails.root + 'tmp' + "harvest_purl_fetcher_job_last_run_#{Rails.env}"

  def perform(first_modified = nil)
    first_modified ||= File.read(STATE_FILE).strip if File.exist? STATE_FILE
    perform_deletes(first_modified)
    most_recent_timestamp = perform_indexes(first_modified)
    write_state_file(most_recent_timestamp) if first_modified.nil? || (most_recent_timestamp > first_modified)
  end

  private

  def perform_deletes(first_modified)
    client = PurlFetcher::Client::DeletesReader.new('', 'purl_fetcher.first_modified' => first_modified)

    client.each do |record|
      DeleteContentFromIndexJob.perform_later(record.druid)
    end
  end

  def perform_indexes(first_modified)
    client = PurlFetcher::Client::Reader.new('', 'purl_fetcher.first_modified' => first_modified)
    last_record = nil
    client.each do |record, _change, meta|
      IndexFullTextContentJob.perform_later(record.druid)
      last_record = meta
    end

    last_record['range']['last_updated'] if last_record
  end

  def write_state_file(timestamp)
    File.open(STATE_FILE, 'w') { |f| f.puts timestamp }
  end
end
