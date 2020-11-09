# frozen_string_literal: true

# Harvest changed content from purl-fetcher
class HarvestPurlFetcherJob < ApplicationJob
  STATE_FILE = Rails.root.join('tmp', "harvest_purl_fetcher_job_last_run_#{Rails.env}")

  def perform(first_modified = nil)
    with_state_file do |f|
      first_modified ||= f.read.strip
      perform_deletes(first_modified)
      perform_indexes(first_modified) do |most_recent_timestamp|
        if most_recent_timestamp > first_modified
          f.rewind
          f.truncate(0)
          f.puts(most_recent_timestamp)
          first_modified = most_recent_timestamp
        end
      end
    end
  end

  private

  def perform_deletes(first_modified)
    client = PurlFetcher::Client::DeletesReader.new('', 'purl_fetcher.first_modified' => first_modified)

    client.each do |record|
      DeleteContentFromIndexJob.perform_later(record.druid)
    end
  end

  # Queue up indexing jobs for content from purl fetcher
  # @param [String] first_modified
  # @yieldparam [Time] the timestamp of the most recently updated document (or the extent of the queried range)
  def perform_indexes(first_modified)
    client = PurlFetcher::Client::Reader.new('', 'purl_fetcher.first_modified' => first_modified)
    client.each_slice(1000) do |batch|
      batch.each do |record, _change|
        # Delete the content and let on-demand indexing reindex it
        DeleteContentFromIndexJob.perform_later(record.druid)
      end

      ts = batch.map { |_, change| Time.zone.parse(change['updated_at']) if change['updated_at'] }.max
      yield ts if ts
    end

    yield client.range['last_modified']
  end

  def with_state_file
    File.open(STATE_FILE, 'w') { |f| f.puts Time.zone.parse('1970-01-01T00:00:00Z') } unless File.exist? STATE_FILE
    File.open(STATE_FILE, 'r+') do |f|
      f.flock(File::LOCK_EX | File::LOCK_NB)
      yield f
    end
  end
end
