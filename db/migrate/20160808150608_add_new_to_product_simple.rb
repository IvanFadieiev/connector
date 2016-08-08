class AddNewToProductSimple < ActiveRecord::Migration
  def change
    add_column :product_simples, :new, :boolean, default: false
  end
end
