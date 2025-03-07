class LeaderboardEntry < ApplicationRecord
  belongs_to :leaderboard
  belongs_to :user, primary_key: :slack_uid, foreign_key: :slack_uid

  validates :slack_uid, presence: true
  validates :total_seconds, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :slack_uid, uniqueness: { scope: :leaderboard_id }
end
