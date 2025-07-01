class AddIsSuperadminToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :is_superadmin, :boolean, default: false, null: false
  end
end
