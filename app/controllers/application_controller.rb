class ApplicationController < ActionController::Base
  include ShopifyApp::Controller
  # before_action :login_again_if_different_shop
  # around_filter :shopify_session
  # layout ShopifyApp.configuration.embedded_app? ? 'embedded_app' : 'application'
  protect_from_forgery with: :exception
  
  def savon_login(login)
    begin
      @login = Login.find(session[:login_id])
      Parser::Login.new.login( login )
      redirect_to success_page_path
    rescue
      redirect_to error_page_path
    end
  end
end
