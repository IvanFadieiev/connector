class AddIndexToJoinTableCategoriesProduct < ActiveRecord::Migration
  def change
    add_index :join_table_categories_products, :category_id
    add_index :join_table_categories_products, :product_id
  end
end
