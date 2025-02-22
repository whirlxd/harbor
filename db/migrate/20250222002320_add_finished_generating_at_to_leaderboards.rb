class AddFinishedGeneratingAtToLeaderboards < ActiveRecord::Migration[8.0]
  def change
    add_column :leaderboards, :finished_generating_at, :datetime
  end
end
