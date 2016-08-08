class CreateCategoryForMonitorings < ActiveRecord::Migration
  def change
    create_table :category_for_monitorings, id: false do |t|
      t.integer :magento_category_id, :limit => 8
      t.integer :shopify_category_id, :limit => 8
      t.string :shopify_domain

      # t.timestamps null: false
    end
  end
end
