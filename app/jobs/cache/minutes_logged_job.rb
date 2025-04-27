class Cache::MinutesLoggedJob < ApplicationJob
  include GoodJob::ActiveJobExtensions::Concurrency

  # Limits concurrency to 1 job
  good_job_control_concurrency_with(
    total: 1,
    drop: true
  )

  def perform(force_reload: false)
    key = "minutes_logged"
    expiration = 1.hour
    Rails.cache.write(key, calculate, expires_in: expiration) if force_reload

    Rails.cache.fetch(key, expires_in: expiration) do
      calculate
    end
  end

  private

  def calculate
    Heartbeat.coding_only
             .with_valid_timestamps
             .where(time: 1.hour.ago..Time.current)
             .duration_seconds / 60
  end
end
