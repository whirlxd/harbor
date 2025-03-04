class CreateApiKeys < ActiveRecord::Migration[8.0]
  def change
    create_table :api_keys do |t|
      t.belongs_to :user, null: false, foreign_key: true
      t.text :name, null: false
      t.text :token, null: false, index: { unique: true }

      t.timestamps
    end

    add_index :api_keys, :token, unique: true
    add_index :api_keys, [ :user_id, :token ], unique: true
    add_index :api_keys, [ :user_id, :name ], unique: true
  end
end
