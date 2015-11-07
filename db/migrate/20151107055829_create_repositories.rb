class CreateRepositories < ActiveRecord::Migration
  def change
    create_table :repositories do |t|
      t.string :name
      t.string :clone_url
      t.references :user, index: true
      t.timestamps null: false
    end
  end
end
