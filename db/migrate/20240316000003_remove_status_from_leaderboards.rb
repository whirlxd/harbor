class RemoveStatusFromLeaderboards < ActiveRecord::Migration[8.0]
  def change
    remove_column :leaderboards, :status, :integer
  end
end
