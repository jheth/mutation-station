class AddStatusToBuilds < ActiveRecord::Migration
  def change
    add_column :builds, :status, :string
    add_index :builds, :status
  end
end
