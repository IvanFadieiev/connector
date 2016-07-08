class LoginController < ApplicationController
    def login
        @login = "login"
    end
    
    def create
        @login = Login.new(login_params)
        if @login.save
            # Parser::Login.new.login( "#{@login.store_url}/api/?wsdl", @login.username, @login.key, @login.store_id )
            # session[:magento_session] = $session
            redirect_to success_page_path
        else
            render error_page_path
        end
    end
    
    def success_page
    end
    
    def error_page
    end
    
    private
    
    def login_params
        params.require(:login).permit(:username, :key, :store_id,:store_url)
    end
end
