class AddCategoriesParsedToLogin < ActiveRecord::Migration
  def change
    add_column :logins, :categories_parsed, :boolean, default: false
  end
end
