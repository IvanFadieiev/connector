class LoginController < ApplicationController
    def login
        @login = "login"
    end
    
    def create
        @login = Login.new(login_params)
        if @login.save
            savon_login
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
