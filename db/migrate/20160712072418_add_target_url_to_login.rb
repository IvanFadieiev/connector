class AddTargetUrlToLogin < ActiveRecord::Migration
  def change
    add_column :logins, :target_url, :string
  end
end
