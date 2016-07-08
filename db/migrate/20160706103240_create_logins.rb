class CreateLogins < ActiveRecord::Migration
  def change
    create_table :logins do |t|
      t.string :username
      t.string :key
      t.integer :store_id

      t.timestamps null: false
    end
  end
end
