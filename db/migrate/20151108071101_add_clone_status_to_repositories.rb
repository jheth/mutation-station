class AddCloneStatusToRepositories < ActiveRecord::Migration
  def change
    add_column :repositories, :clone_status, :integer, nil: false, default: 0
  end
end
