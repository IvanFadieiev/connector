class LoginController < ApplicationController
    before_action :authenticate_vendor!
    before_filter :set_login, except: [:create]
    around_filter :shopify_session, only: :create
    def login
        @login = "login"
    end
    
    def create
        @exist_login = Login.find_by(target_url: ShopifyAPI::Shop.current.domain, vendor_id: current_vendor.id)
        if @exist_login.blank?
            @login = Login.new(login_params)
            if @login.save
                @login.update_column(:vendor_id, current_vendor.id )
                @login.update_column(:target_url, ShopifyAPI::Shop.current.domain )
                session[:login_id] = @login.id
                savon_login(@login)
            else
                flash.now[:notice] = "Sorry! Try again!"
                render "home/index"
            end
        else
            Parser::Login.new.login(@exist_login)
            redirect_to exists_login_path
        end
    end
    
    def success_page
    end
    
    def error_page
    end
    
    private
    
    def create_dirs(id)
        dirs = []
        dirs << File.dirname("#{Rails.root}/public/#{id}
        # /categories/categories.log")
        # dirs << File.dirname("#{Rails.root}/public/#{id}/categories_products/categories_products.log")
        # dirs << File.dirname("#{Rails.root}/public/#{id}/image/image.log")
        # dirs << File.dirname("#{Rails.root}/public/#{id}/image/category/image.log")
        # dirs << File.dirname("#{Rails.root}/public/#{id}/image/products/image.log")
        # dirs << File.dirname("#{Rails.root}/public/#{id}/products/products.log")
        dirs.map do |dir|
          FileUtils.mkdir_p(dir) unless File.directory?(dir)
        end
    end
    
    def set_login
        @login = Login.find(session[:login_id])
    end
    
    def login_params
        params.require(:login).permit(:username, :key, :store_id,:store_url, :email )
    end
end
