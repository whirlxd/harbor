class LeaderboardEntry < ApplicationRecord
  belongs_to :leaderboard
  belongs_to :user, primary_key: :slack_uid

  validates :user_id, presence: true
  validates :total_seconds, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :user_id, uniqueness: { scope: :leaderboard_id }
end
