class AddShopifyProductIdToProductSimple < ActiveRecord::Migration
  def change
    add_column :product_simples, :shopify_product_id, :integer, :limit => 8
  end
end
