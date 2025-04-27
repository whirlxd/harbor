class Cache::SocialProofJob < ApplicationJob
  include GoodJob::ActiveJobExtensions::Concurrency

  # Limits concurrency to 1 job
  good_job_control_concurrency_with(
    total: 1,
    drop: true
  )

  def perform(force_reload: false)
    key = "social_proof"
    expiration = 1.hour
    Rails.cache.write(key, calculate, expires_in: expiration) if force_reload

    Rails.cache.fetch(key, expires_in: expiration) do
      calculate
    end
  end

  private

  def calculate
    # Only run queries as needed, starting with the smallest time range
    if (past_hour_count = users_in_past(1.hour)) > 5
      "In the past hour, #{past_hour_count} Hack Clubbers have coded with Hackatime."
    elsif (past_day_count = users_in_past(1.day)) > 5
      "In the past day, #{past_day_count} Hack Clubbers have coded with Hackatime."
    elsif (past_week_count = users_in_past(1.week)) > 5
      "In the past week, #{past_week_count} Hack Clubbers have coded with Hackatime."
    end
  end

  def users_in_past(duration)
    Heartbeat.coding_only
             .with_valid_timestamps
             .where("time > ?", duration.ago.to_f)
             .distinct.count(:user_id)
  end
end
