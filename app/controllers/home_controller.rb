class HomeController < AuthenticatedController
  before_action :authenticate_vendor!
  require "parser"
  def index
    # @products = ShopifyAPI::Product.find(:all, :params => {:limit => 10})
    @exists_logins = current_vendor.logins
    @login = Login.new
  end
end
