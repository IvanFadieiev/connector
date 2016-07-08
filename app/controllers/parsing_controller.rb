class ParsingController < ApplicationController
    before_filter :set_login
    
    def category
        ParserProcess.new.delay.parse_categories(@login)
        check_categories_parsing
    end
    
    def check_categories_parsing
        if @login.categories_parsed
            path = category_product_join_table_url
            render json: { path: path }
        else
            render :parsing_categories_start
        end
    end
    
    def parsing_categories_start
    end
    
    def category_product_join_table
        @all_categories = []
        SmarterCSV.process( "public/categories/categories.csv" ).map{ |a| @all_categories << a if (a[:level]==2 && a[:is_active] == 1) }
        @shopify_collect = ShopifyAPI::CustomCollection.all
    end
    
    def accepted_collection
        byebug
    end
    
    private
    
    def set_login
        @login = Login.find(session[:login_id])
    end
end
