# frozen_string_literal: true

# Basic lock manager
module Locking
  def with_lock(id)
    lock_file = Rails.root.join('tmp', id)

    resp = File.open(lock_file, 'w') do |f|
      f.flock(File::LOCK_EX)
      yield(true)
    end

    File.delete(lock_file) if File.exist?(lock_file)

    resp
  end
end
