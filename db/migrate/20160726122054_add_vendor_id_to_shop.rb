class AddVendorIdToShop < ActiveRecord::Migration
  def change
    add_column :shops, :vendor_id, :integer
    add_index :shops, :vendor_id
  end
end
