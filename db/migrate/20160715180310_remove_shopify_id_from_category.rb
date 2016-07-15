class RemoveShopifyIdFromCategory < ActiveRecord::Migration
  def change
    remove_column :categories, :shopify_category_id, :integer
  end
end
