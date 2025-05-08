class Cache::SetupSocialProofJob < Cache::ActivityJob
  queue_as :latency_10s

  private

  def calculate
    # Only run queries as needed, starting with the smallest time range
    if (past_5min_count = users_in_past(5.minutes)) >= 1
      "#{past_5min_count} #{'Hack Clubber'.pluralize(past_5min_count)} set up Hackatime in the last 5 minutes"
    elsif (past_hour_count = users_in_past(1.hour)) >= 3
      "#{past_hour_count} #{'Hack Clubber'.pluralize(past_hour_count)} set up Hackatime in the last hour"
    elsif (past_day_count = users_in_past(1.day)) >= 5
      "#{past_day_count} #{'Hack Clubber'.pluralize(past_day_count)} set up Hackatime today"
    elsif (past_week_count = users_in_past(1.week)) >= 5
      "#{past_week_count} #{'Hack Clubber'.pluralize(past_week_count)} set up Hackatime in the past week"
    elsif (past_month_count = users_in_past(1.month)) >= 5
      "#{past_month_count} #{'Hack Clubber'.pluralize(past_month_count)} set up Hackatime in the past month"
    elsif (year_count = users_in_past(Time.current.beginning_of_year)) >= 5
      "#{year_count} #{'Hack Clubber'.pluralize(year_count)} set up Hackatime this year"
    end
  end

  def users_in_past(time_period)
    Heartbeat.where("time > ?", time_period.to_f)
             .where(source_type: :test_entry)
             .distinct
             .count(:user_id)
  end
end 