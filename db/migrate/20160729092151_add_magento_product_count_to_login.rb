class AddMagentoProductCountToLogin < ActiveRecord::Migration
  def change
    add_column :logins, :magento_product_count, :integer
  end
end
