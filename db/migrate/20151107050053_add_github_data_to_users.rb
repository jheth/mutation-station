class AddGithubDataToUsers < ActiveRecord::Migration
  def change
    add_column :users, :github_avatar_url, :string
    add_column :users, :github_username, :string
    add_column :users, :github_access_token, :string
  end
end
