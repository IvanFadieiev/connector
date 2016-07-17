class AddIndexToCollection < ActiveRecord::Migration
  def change
    add_index :collections, :shopify_category_id
    add_index :collections, :magento_category_id
  end
end
