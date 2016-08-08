class AddNewToProduct < ActiveRecord::Migration
  def change
    add_column :products, :new, :boolean, default: false
  end
end
