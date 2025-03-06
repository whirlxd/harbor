class ChangeHeartbeatsTimeToFloat8 < ActiveRecord::Migration[8.0]
  def change
    change_column :heartbeats, :time, :float8, null: false
  end
end
