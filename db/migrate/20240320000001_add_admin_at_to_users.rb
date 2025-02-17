class AddAdminAtToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :admin_at, :datetime
  end
end
