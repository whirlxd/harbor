class Heartbeat < WakatimeRecord
  TIMEOUT_DURATION = 2.minutes

  def self.cached_recent_count
    Rails.cache.fetch("heartbeats_recent_count", expires_in: 5.minutes) do
      recent.count
    end
  end

  scope :recent, -> { where("created_at > ?", 24.hours.ago) }
  scope :today, -> { where("DATE(created_at) = ?", Date.current) }

  # This is a hack to avoid using the default Rails inheritance column– Rails is confused by the field `type` in the db
  self.inheritance_column = nil
  # Prevent collision with Ruby's hash method
  self.ignored_columns += [ "hash" ]

  def self.duration_seconds(scope = all)
    scope.order(created_at: :asc).each_cons(2).sum do |current, next_beat|
      time_diff = (next_beat.created_at - current.created_at)
      [ time_diff, TIMEOUT_DURATION ].min
    end.to_i
  end

  def self.duration_formatted(scope = all)
    seconds = duration_seconds(scope)
    hours = seconds / 3600
    minutes = (seconds % 3600) / 60
    remaining_seconds = seconds % 60

    format("%02d:%02d:%02d", hours, minutes, remaining_seconds)
  end
end
