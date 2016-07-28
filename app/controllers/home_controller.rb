class HomeController < AuthenticatedController
  before_action :authenticate_vendor!
  require "parser"

  def index
    # @products = ShopifyAPI::Product.find(:all, :params => {:limit => 10})
    @login = Login.new
  end
end
