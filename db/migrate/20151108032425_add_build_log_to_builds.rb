class AddBuildLogToBuilds < ActiveRecord::Migration
  def change
    add_column :builds, :build_log, :text
  end
end
