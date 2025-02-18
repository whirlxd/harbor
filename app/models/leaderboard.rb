class Leaderboard < ApplicationRecord
  has_many :entries,
    class_name: "LeaderboardEntry",
    dependent: :destroy

  validates :start_date, presence: true, uniqueness: true
end
