class AddTimezoneUtcOffsetToLeaderboards < ActiveRecord::Migration[8.0]
  def change
    add_column :leaderboards, :timezone_utc_offset, :integer
  end
end
