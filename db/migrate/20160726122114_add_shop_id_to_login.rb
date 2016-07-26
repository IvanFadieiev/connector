class AddShopIdToLogin < ActiveRecord::Migration
  def change
    add_column :logins, :shop_id, :integer
    add_index :logins, :shop_id
  end
end
