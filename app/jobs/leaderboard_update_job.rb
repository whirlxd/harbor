class LeaderboardUpdateJob < ApplicationJob
  queue_as :default
  BATCH_SIZE = 100

  include GoodJob::ActiveJobExtensions::Concurrency

  # Limits concurrency to 1 job per date
  good_job_control_concurrency_with(
    key: -> { arguments.first || Date.current.to_s },
    total: 1,
    drop: true
  )

  def perform(date = Date.current)
    parsed_date = date.is_a?(Date) ? date : Date.parse(date.to_s)
    leaderboard = Leaderboard.create!(start_date: parsed_date)

    # Get list of valid user IDs from our database
    valid_user_ids = User.pluck(:slack_uid)
    return if valid_user_ids.empty?

    ActiveRecord::Base.transaction do
      valid_user_ids.each_slice(BATCH_SIZE) do |batch_user_ids|
        entries_data = Hackatime.where(user_id: batch_user_ids)
                                           .where(time: parsed_date.all_day)
                                           .group(:user_id)
                                           .duration_seconds

        entries_data = entries_data.map do |user_id, total_seconds|
          {
            leaderboard_id: leaderboard.id,
            user_id: user_id,
            total_seconds: total_seconds
          }
        end

        # Batch insert new entries for this batch
        LeaderboardEntry.insert_all!(entries_data) if entries_data.any?
      end
    end

    # Set finished_generating_at after successful completion
    leaderboard.finished_generating_at = Time.current
    leaderboard.save!

    # Delete previous leaderboard entries from today
    Leaderboard.where.not(id: leaderboard.id).where(start_date: parsed_date).where(deleted_at: nil).update_all(deleted_at: Time.current)
  rescue => e
    Rails.logger.error "Failed to update current leaderboard: #{e.message}"
    raise
  rescue Date::Error
    raise ArgumentError, "Invalid date format provided"
  end
end
