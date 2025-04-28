class Cache::HomeStatsJob < Cache::ActivityJob
  private

  def calculate
    seconds_by_user = Heartbeat.group(:user_id).duration_seconds
    {
      users_tracked: seconds_by_user.size,
      seconds_tracked: seconds_by_user.values.sum
    }
  end
end
