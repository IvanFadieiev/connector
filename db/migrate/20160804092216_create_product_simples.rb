class CreateProductSimples < ActiveRecord::Migration
  def change
    create_table :product_simples do |t|
      t.integer :product_id
      t.integer :parent_id
      t.string :sku
      t.string :size
      t.string :length
      t.integer :qty
      t.integer :login_id

      t.timestamps null: false
    end
    add_index :product_simples, :parent_id
  end
end
