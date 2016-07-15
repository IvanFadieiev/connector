class AddShopifyProductIdToProduct < ActiveRecord::Migration
  def change
    add_column :products, :shopify_product_id, :integer, :limit => 8
  end
end
