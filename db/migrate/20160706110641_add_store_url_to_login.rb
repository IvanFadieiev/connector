class AddStoreUrlToLogin < ActiveRecord::Migration
  def change
    add_column :logins, :store_url, :string
  end
end
