class CreateProductImages < ActiveRecord::Migration
  def change
    create_table :product_images do |t|
      t.integer :product_id
      t.string :img_url
      t.integer :login_id

      t.timestamps null: false
    end
  end
end
