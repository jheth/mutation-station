class CreateBuilds < ActiveRecord::Migration
  def change
    create_table :builds do |t|
      t.references :repository, null: false
      t.string :last_sha
      t.json :result
      t.string :stdout
      t.references :user, null: false

      t.timestamps null: false
    end
    add_index :builds, :repository_id
    add_index :builds, :user_id
  end
end
