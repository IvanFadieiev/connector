class LoginController < ApplicationController
    before_filter :set_login, except: [:create]
    def login
        @login = "login"
    end
    
    def create
        @login = Login.new(login_params)
        if @login.save
            create_dirs(@login.id)
            session[:login_id] = @login.id
            savon_login
        end
    end
    
    def success_page
    end
    
    def error_page
    end
    
    private
    
    def create_dirs(id)
        dirs = []
        dirs << File.dirname("#{Rails.root}/public/#{id}/categories/categories.log")
        dirs << File.dirname("#{Rails.root}/public/#{id}/categories_products/categories_products.log")
        dirs << File.dirname("#{Rails.root}/public/#{id}/image/image.log")
        dirs << File.dirname("#{Rails.root}/public/#{id}/image/category/image.log")
        dirs << File.dirname("#{Rails.root}/public/#{id}/image/products/image.log")
        dirs << File.dirname("#{Rails.root}/public/#{id}/products/products.log")
        dirs.map do |dir|
          FileUtils.mkdir_p(dir) unless File.directory?(dir)
        end
    end
    
    def set_login
        @login = Login.find(session[:login_id])
    end
    
    def login_params
        params.require(:login).permit(:username, :key, :store_id,:store_url)
    end
end
