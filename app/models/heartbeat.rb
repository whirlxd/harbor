class Heartbeat < WakatimeRecord
  TIMEOUT_DURATION = 2.minutes

  def self.cached_recent_count
    Rails.cache.fetch("heartbeats_recent_count", expires_in: 5.minutes) do
      recent.count
    end
  end

  scope :recent, -> { where("time > ?", 24.hours.ago) }
  scope :today, -> { where("DATE(time) = ?", Date.current) }

  # This is a hack to avoid using the default Rails inheritance column– Rails is confused by the field `type` in the db
  self.inheritance_column = nil
  # Prevent collision with Ruby's hash method
  self.ignored_columns += [ "hash" ]

  def self.duration_seconds(scope = all)
    capped_diffs = scope
      .select("CASE
        WHEN LAG(time) OVER (ORDER BY time) IS NULL THEN 0
        ELSE LEAST(EXTRACT(EPOCH FROM (time - LAG(time) OVER (ORDER BY time))), #{TIMEOUT_DURATION.to_i})
      END as diff")
      .where.not(time: nil)
      .order(time: :asc)

    connection.select_value("SELECT COALESCE(SUM(diff), 0)::integer FROM (#{capped_diffs.to_sql}) AS diffs").to_i
  end

  def self.duration_formatted(scope = all)
    seconds = duration_seconds(scope)
    hours = seconds / 3600
    minutes = (seconds % 3600) / 60
    remaining_seconds = seconds % 60

    format("%02d:%02d:%02d", hours, minutes, remaining_seconds)
  end
end
