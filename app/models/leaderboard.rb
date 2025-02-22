class Leaderboard < ApplicationRecord
  has_many :entries,
    class_name: "LeaderboardEntry",
    dependent: :destroy

  validates :start_date, presence: true

  def finished_generating?
    finished_generating_at.present?
  end
end
