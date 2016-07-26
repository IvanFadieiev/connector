class Shop < ActiveRecord::Base
    belongs_to :vendors
    has_one    :login
  include ShopifyApp::Shop
end
