class AddIndexToTargetCategoryImport < ActiveRecord::Migration
  def change
    add_index :target_category_imports, :magento_category_id
    add_index :target_category_imports, :shopify_category_id
  end
end
