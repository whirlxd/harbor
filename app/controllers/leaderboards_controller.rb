class LeaderboardsController < ApplicationController
  def index
    @leaderboard = Leaderboard.find_by(start_date: Date.current)

    @entries = @leaderboard.entries
      .includes(:user)
      .order(total_seconds: :desc)
  end
end
