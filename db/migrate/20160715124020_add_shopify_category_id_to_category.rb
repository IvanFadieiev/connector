class AddShopifyCategoryIdToCategory < ActiveRecord::Migration
  def change
    add_column :categories, :shopify_category_id, :integer
  end
end
