class AddCounterToLogin < ActiveRecord::Migration
  def change
    add_column :logins, :counter, :integer
  end
end
