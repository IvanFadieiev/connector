class HomeController < AuthenticatedController
  require "parser"
  def index
    # @products = ShopifyAPI::Product.find(:all, :params => {:limit => 10})
    @login = Login.new
  end
end
