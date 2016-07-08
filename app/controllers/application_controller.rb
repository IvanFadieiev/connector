class ApplicationController < ActionController::Base
  include ShopifyApp::Controller
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  
  def savon_login
    begin
      @login = Login.last
      Parser::Login.new.login( "#{@login.store_url}/api/?wsdl", @login.username, @login.key, @login.store_id )
      redirect_to success_page_path
    rescue
      redirect_to error_page_path
    end
  end
end
