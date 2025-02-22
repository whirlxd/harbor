class AddDeletedAtToLeaderboards < ActiveRecord::Migration[8.0]
  def change
    add_column :leaderboards, :deleted_at, :datetime, null: true
  end
end
