class CreateJoinTableCategoriesProducts < ActiveRecord::Migration
  def change
    create_table :join_table_categories_products do |t|
      t.integer :category_id
      t.integer :product_id
      t.integer :login_id

      t.timestamps null: false
    end
  end
end
