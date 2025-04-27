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
    counts = Heartbeat.select(
      "COUNT(DISTINCT user_id) FILTER (WHERE time > #{1.hour.ago.to_f}) as hour_count",
      "COUNT(DISTINCT user_id) FILTER (WHERE time > #{1.day.ago.to_f}) as day_count",
      "COUNT(DISTINCT user_id) FILTER (WHERE time > #{1.week.ago.to_f}) as week_count"
    ).take

    if counts.hour_count > 5
      "In the past hour, #{counts.hour_count} Hack Clubbers have coded with Hackatime."
    elsif counts.day_count > 5
      "In the past day, #{counts.day_count} Hack Clubbers have coded with Hackatime."
    elsif counts.week_count > 5
      "In the past week, #{counts.week_count} Hack Clubbers have coded with Hackatime."
    end
  end
end
