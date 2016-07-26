class SessionsController < ApplicationController
  include ShopifyApp::SessionsController
  before_action :authenticate_vendor!
  # before_filter :method_name
  
  # def method_name
  #   byebug
  # end
end
