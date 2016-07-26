class AddVendorIdToLogin < ActiveRecord::Migration
  def change
    add_column :logins, :vendor_id, :integer
    add_index :logins, :vendor_id
  end
end
