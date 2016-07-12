class CreateTargetCategoryImports < ActiveRecord::Migration
  def change
    create_table :target_category_imports do |t|
      t.integer :magento_category_id
      t.integer :shopify_category_id
      t.integer :login_id

      t.timestamps null: false
    end
  end
end
