class Cache::MinutesLoggedJob < Cache::ActivityJob
  private

  def calculate
    Heartbeat.coding_only
             .with_valid_timestamps
             .where(time: 1.hour.ago..Time.current)
             .duration_seconds / 60
  end
end
