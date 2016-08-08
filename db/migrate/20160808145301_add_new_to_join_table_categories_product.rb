class AddNewToJoinTableCategoriesProduct < ActiveRecord::Migration
  def change
    add_column :join_table_categories_products, :new, :boolean, default: false
  end
end
