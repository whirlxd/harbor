class LeaderboardsController < ApplicationController
  def index
    @leaderboard = Leaderboard.find_by(start_date: Date.current)

    if @leaderboard.nil?
      LeaderboardUpdateJob.perform_later
      flash.now[:notice] = "Leaderboard is being updated..."
    else
      @entries = @leaderboard.entries
        .includes(:user)
        .order(total_seconds: :desc)
    end
  end
end
