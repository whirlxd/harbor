class Heartbeat < WakatimeRecord
  def self.cached_recent_count
    Rails.cache.fetch("heartbeats_recent_count", expires_in: 5.minutes) do
      recent.count
    end
  end

  scope :recent, -> { where("created_at > ?", 24.hours.ago) }
end
