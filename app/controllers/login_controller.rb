class LoginController < ApplicationController
    before_filter :set_login, except: [:create]
    def login
        @login = "login"
    end
    
    def create
        @login = Login.new(login_params)
        if @login.save
            session[:login_id] = @login.id
            savon_login
        end
    end
    
    def success_page
    end
    
    def error_page
    end
    
    private
    
    def set_login
        @login = Login.find(session[:login_id])
    end
    
    def login_params
        params.require(:login).permit(:username, :key, :store_id,:store_url)
    end
end
