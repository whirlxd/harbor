class WarmMiniLeaderboardCacheJob < ApplicationJob
  queue_as :default

  def perform
    offsets = [ -8, -7, -6, -5, -4, -3, 0, 1, 2, 8, 9, 10, 11, 12 ]

    offsets.each do |offset|
      begin
        # for some fucnking reason this shit broke now im pissed
        [:daily, :weekly, :last_7_days].each do |period_type|
          generate_timezone_leaderboard(offset, period_type)
        end
        
        Rails.logger.info "made leaderboard offset #{offset >= 0 ? '+' : ''}#{offset}"
      rescue => e
        Rails.logger.error "didnt make leaderboard offset #{offset >= 0 ? '+' : ''}#{offset}: #{e.message}"
      end
    end
  end

  private

  def generate_timezone_leaderboard(offset, period_type)
    date = case period_type
    when :weekly then Date.current.beginning_of_week
    when :last_7_days then Date.current - 6.days
    else Date.current
    end

    leaderboard = Leaderboard.create!(
      start_date: date,
      period_type: period_type,
      timezone_utc_offset: offset
    )

    users = User.users_in_timezone_offset(offset).not_convicted
    user_ids = users.pluck(:id)
    
    return leaderboard if user_ids.empty?

    date_range = case period_type
    when :weekly
      date.beginning_of_day...(date + 7.days).beginning_of_day
    when :last_7_days
      (date - 6.days).beginning_of_day...date.end_of_day
    else
      date.all_day
    end

    ActiveRecord::Base.transaction do
      entries_data = Heartbeat.where(user_id: user_ids, time: date_range)
                              .coding_only
                              .with_valid_timestamps
                              .joins(:user)
                              .where.not(users: { github_uid: nil })
                              .group(:user_id)
                              .duration_seconds

      entries_data = entries_data.filter { |_, total_seconds| total_seconds > 60 }
      
      streaks = Heartbeat.daily_streaks_for_users(entries_data.keys) if entries_data.any?

      entries_to_create = entries_data.map do |user_id, total_seconds|
        {
          leaderboard_id: leaderboard.id,
          user_id: user_id,
          total_seconds: total_seconds,
          streak_count: streaks[user_id] || 0
        }
      end

      LeaderboardEntry.insert_all!(entries_to_create) if entries_to_create.any?
    end

    leaderboard.update!(finished_generating_at: Time.current)

    Leaderboard.where.not(id: leaderboard.id)
               .where(start_date: date, period_type: period_type, timezone_utc_offset: offset)
               .where(deleted_at: nil)
               .update_all(deleted_at: Time.current)

    leaderboard
  end
end
