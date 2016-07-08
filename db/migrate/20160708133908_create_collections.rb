class CreateCollections < ActiveRecord::Migration
  def change
    create_table :collections do |t|
      t.integer :shopify_category_id
      t.integer :magento_category_id

      t.timestamps null: false
    end
  end
end
