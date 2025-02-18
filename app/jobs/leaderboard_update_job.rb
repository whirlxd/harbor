class LeaderboardUpdateJob < ApplicationJob
  queue_as :default
  limits_concurrency to: 1, key: :date, duration: 5.minutes

  def perform(date = nil, leaderboard = nil)
    if !leaderboard
      date ||= Date.current
      leaderboard = Leaderboard.find_or_initialize_by(start_date: date)
    end

    ActiveRecord::Base.transaction do
      # Reset the leaderboard to recalculate
      leaderboard.entries.destroy_all

      begin
        User.find_each do |user|
          seconds = user.heartbeats.where("DATE(time) = ?", date).duration_seconds
          next if seconds.zero?

          leaderboard.entries.build(
            user_id: user.slack_uid,
            total_seconds: seconds
          )
        end

        leaderboard.touch(:updated_at) unless leaderboard.new_record?
        leaderboard.save!
      rescue => e
        Rails.logger.error "Failed to update current leaderboard: #{e.message}"
        raise
      end
    end
  end
end
