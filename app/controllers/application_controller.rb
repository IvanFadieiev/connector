class ApplicationController < ActionController::Base
  include ShopifyApp::Controller
  before_action :login_again_if_different_shop
  # around_filter :shopify_session
  # layout ShopifyApp.configuration.embedded_app? ? 'embedded_app' : 'application'
  protect_from_forgery with: :exception
  # before_action :current_vendor_verification
  
  # def current_vendor_verification
  #   unless current_vendor
  #     redirect_to new_vendor_session_path  
  #   end
  # end
  
  def savon_login(login)
    begin
      @login = Login.find(login.id)
      Parser::Login.new.login( login )
      redirect_to success_page_path
    rescue
      redirect_to error_page_path
    end
  end
end
