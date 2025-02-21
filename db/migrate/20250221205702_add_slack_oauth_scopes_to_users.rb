class AddSlackOauthScopesToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :slack_scopes, :string, array: true, default: []
    add_column :users, :slack_access_token, :text
  end
end
