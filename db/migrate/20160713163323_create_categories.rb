class CreateCategories < ActiveRecord::Migration
  def change
    create_table :categories do |t|
      t.integer :category_id
      t.integer :parent_id
      t.string :name
      t.text :description
      t.string :is_active
      t.integer :level
      t.string :image
      t.integer :login_id

      t.timestamps null: false
    end
  end
end
