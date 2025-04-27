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
    if (in_past_hour = Heartbeat.where("time > ?", 1.hour.ago.to_f).distinct.count(:user_id)) > 5
      "In the past hour, #{in_past_hour} Hack Clubbers have coded with Hackatime."
    elsif (in_past_day = Heartbeat.where("time > ?", 1.day.ago.to_f).distinct.count(:user_id)) > 5
      "In the past day, #{in_past_day} Hack Clubbers have coded with Hackatime."
    elsif (in_past_week = Heartbeat.where("time > ?", 1.week.ago.to_f).distinct.count(:user_id)) > 5
      "In the past week, #{in_past_week} Hack Clubbers have coded with Hackatime."
    end
  end
end
