class RenameAvatarUrlToSlackAvatarUrlOnUsers < ActiveRecord::Migration[8.0]
  def change
    rename_column :users, :avatar_url, :slack_avatar_url
  end
end
