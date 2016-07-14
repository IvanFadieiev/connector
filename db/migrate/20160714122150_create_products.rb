class CreateProducts < ActiveRecord::Migration
  def change
    create_table :products do |t|
      t.integer :product_id
      t.string :prod_type
      t.string :sku
      t.string :name
      t.string :ean
      t.text   :description
      t.string :price
      t.string :special_price
      t.string :special_from_date
      t.string :special_to_date
      t.string :url_key
      t.string :image
      t.string :color
      t.string :status
      t.string :weight
      t.string :set
      t.string :size
      t.integer :login_id

      t.timestamps null: false
    end
  end
end
