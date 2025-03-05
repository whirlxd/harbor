class EnforceUniquenessIndexOnHeartbeats < ActiveRecord::Migration[8.0]
  def change
    add_index :heartbeats, :fields_hash, unique: true, if_not_exists: true
  end
end
