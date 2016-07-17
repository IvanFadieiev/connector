class AddIndexToProductImage < ActiveRecord::Migration
  def change
    add_index :product_images, :product_id
  end
end
