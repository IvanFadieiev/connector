class SessionsController < ApplicationController
  before_action :authenticate_vendor!
  include ShopifyApp::SessionsController
end
