class AddLoginIdToCollections < ActiveRecord::Migration
  def change
    add_column :collections, :login_id, :integer
  end
end
