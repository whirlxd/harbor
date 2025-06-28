class RequestCounter
  WINDOW_SIZE = 10 # seconds - shorter window for more responsive rates
  HIGH_LOAD_THRESHOLD = 500 # req/sec to disable tracking
  CIRCUIT_BREAKER_DURATION = 30 # seconds to stay disabled
  PROCESS_ID = "#{Socket.gethostname}-#{Process.pid}"
  STATS_DIR = Rails.root.join("tmp", "request_stats")

  @buckets = {}
  @disabled_until = nil
  @last_sync = 0

  class << self
    def increment
      return if disabled?

      current_time = Time.current.to_i
      @buckets[current_time] = (@buckets[current_time] || 0) + 1

      # Check if we should disable due to high load
      check_circuit_breaker(current_time)

      # Periodically sync to file and cleanup (1% chance)
      if rand(100) == 0
        sync_to_file(current_time)
        cleanup
      end
    end

    def per_second
      return :high_load if disabled?

      current_time = Time.current.to_i
      cutoff = current_time - WINDOW_SIZE

      # Fast local calculation
      local_total = @buckets.select { |timestamp, _| timestamp >= cutoff }.values.sum
      (local_total.to_f / WINDOW_SIZE).round(2)
    end

    def global_per_second
      return :high_load if disabled?

      current_time = Time.current.to_i
      sync_to_file(current_time)

      # Read and aggregate from all process files
      cutoff = current_time - WINDOW_SIZE
      total = 0

      Dir.glob(STATS_DIR.join("*.txt")).each do |file_path|
        next unless File.mtime(file_path) > (cutoff - 60).seconds.ago # Skip very old files

        begin
          File.read(file_path).each_line do |line|
            next if line.strip.empty?
            timestamp, count = line.strip.split(":", 2)
            next unless timestamp && count
            total += count.to_i if timestamp.to_i >= cutoff
          end
        rescue Errno::ENOENT
          # Skip deleted files
        end
      end

      (total.to_f / WINDOW_SIZE).round(2)
    end

    private

    def disabled?
      @disabled_until && Time.current.to_i < @disabled_until
    end

    def check_circuit_breaker(current_time)
      # Check last 5 seconds for high load (local only for performance)
      recent_total = @buckets.select { |ts, _| ts >= current_time - 5 }.values.sum

      if recent_total > HIGH_LOAD_THRESHOLD * 5 # 5 seconds worth
        @disabled_until = current_time + CIRCUIT_BREAKER_DURATION
        @buckets.clear # Clear to reduce memory
      end
    end

    def sync_to_file(current_time)
      return if current_time == @last_sync || @buckets.empty?

      ensure_stats_dir
      file_path = STATS_DIR.join("#{PROCESS_ID}.txt")

      # Atomic write: write to temp file then rename
      temp_path = "#{file_path}.tmp"
      data = @buckets.map { |timestamp, count| "#{timestamp}:#{count}" }.join("\n")
      File.write(temp_path, data)
      File.rename(temp_path, file_path)

      @last_sync = current_time
    rescue Errno::ENOENT, Errno::EACCES
      # Silently fail if we can't write (e.g., read-only filesystem)
    end

    def ensure_stats_dir
      FileUtils.mkdir_p(STATS_DIR) unless Dir.exist?(STATS_DIR)
    end

    def cleanup
      current_time = Time.current.to_i
      cutoff = current_time - WINDOW_SIZE - 10 # extra buffer
      @buckets.reject! { |timestamp, _| timestamp < cutoff }

      # Clean up old process files (10% chance)
      return unless rand(10) == 0

      Dir.glob(STATS_DIR.join("*.txt")).each do |file_path|
        File.delete(file_path) if File.mtime(file_path) < (cutoff - 60).seconds.ago
      rescue Errno::ENOENT
        # File already deleted
      end
    end
  end
end
