class AddStatusToBuilds < ActiveRecord::Migration
  def change
    add_column :builds, :status, :integer, nil: false, default: 0
    add_index :builds, :status
  end
end
