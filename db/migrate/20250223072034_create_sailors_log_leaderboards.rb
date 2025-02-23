class CreateSailorsLogLeaderboards < ActiveRecord::Migration[8.0]
  def change
    create_table :sailors_log_leaderboards do |t|
      t.timestamps
    end
  end
end
