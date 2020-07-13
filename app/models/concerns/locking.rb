# frozen_string_literal: true

# Basic lock manager
module Locking
  def with_lock(id, &block)
    if Rails.application.config.active_job.queue_adapter == :sidekiq
      with_redlock(id, &block)
    else
      with_simple_lock(id, &block)
    end
  end

  private

  def with_redlock(id)
    Sidekiq.redis_pool.with do |redis|
      lock_manager = Redlock::Client.new([redis], { retry_count: 60, retry_delay: 1000 })

      # if the lock is available the first try
      lock_manager.lock(id, 60000, { extend: { value: SecureRandom.uuid } }) do |locked|
        return yield(true) if locked
      end

      # otherwise, let the lock requestor know that someone else beat them to the punch
      lock_manager.lock(id, 60000) do |locked|
        yield(false) if locked
      end
    end
  end

  def with_simple_lock(id)
    lock_file = Rails.root + 'tmp' + id

    resp = File.open(lock_file, 'w') do |f|
      f.flock(File::LOCK_EX)
      yield(true)
    end

    File.delete(lock_file) if File.exist?(lock_file)

    resp
  end
end
