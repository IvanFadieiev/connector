class AddShopifyProductIdToProductSimple < ActiveRecord::Migration
  def change
    add_column :product_simples, :shopify_product_id, :integer
  end
end
