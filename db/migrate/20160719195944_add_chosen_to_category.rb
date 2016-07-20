class AddChosenToCategory < ActiveRecord::Migration
  def change
    add_column :categories, :chosen, :boolean
  end
end
