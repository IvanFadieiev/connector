class AddIndexToProduct < ActiveRecord::Migration
  def change
    add_index :products, :product_id
  end
end
