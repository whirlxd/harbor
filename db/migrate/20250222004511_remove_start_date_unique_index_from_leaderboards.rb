class RemoveStartDateUniqueIndexFromLeaderboards < ActiveRecord::Migration[8.0]
  def change
    remove_index :leaderboards, :start_date
  end
end
