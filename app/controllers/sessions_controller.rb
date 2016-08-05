class SessionsController < ApplicationController
  include ShopifyApp::SessionsController
  before_action :authenticate_vendor!
end
