class AddIndexToCategory < ActiveRecord::Migration
  def change
    add_index :categories, :category_id
    add_index :categories, :parent_id
  end
end
