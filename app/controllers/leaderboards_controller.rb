class LeaderboardsController < ApplicationController
  def index
    @leaderboard = Leaderboard.find_by(start_date: Date.current, deleted_at: nil)

    if @leaderboard.nil?
      LeaderboardUpdateJob.perform_later
      flash.now[:notice] = "Leaderboard is being updated..."
    else
      @entries = @leaderboard.entries
                             .includes(:user)
                             .order(total_seconds: :desc)

      @untracked_entries = Hackatime::Heartbeat.today
                                               .where.not(user_id: @leaderboard.entries.select(:slack_uid))
                                               .distinct.pluck(:user_id)
                                               .size
    end
  end
end
