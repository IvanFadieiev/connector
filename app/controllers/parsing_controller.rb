class ParsingController < ApplicationController
    before_filter :set_login
    # before_filter :activ_categories, only: [:category_product_join_table, :accepted_collection]
    
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
        SmarterCSV.process( "public/#{@login.id}/categories/categories.csv" ).map{ |a| @all_categories << a if (a[:level]==2 && a[:is_active] == 1) }
        @collection = Collection.new
        @shopify_collect = ShopifyAPI::CustomCollection.all
    end
    
    def accepted_collection
        @all_categories = []
        SmarterCSV.process( "public/#{@login.id}/categories/categories.csv" ).map{ |a| @all_categories << a if (a[:level]==2 && a[:is_active] == 1) }
        @all_categories.map do |category|
            cat_id = category[:category_id]
            param_shopify = "#{cat_id}_shopify_categories_ids".to_sym
            ids = params[param_shopify]
            unless ids.blank?
                ids.map do |shopify_category_id|
                    param_magento = "#{cat_id}_magento_category_id".to_sym
                    Collection.delay.create(
                                      shopify_category_id:  shopify_category_id,
                                      magento_category_id: params[param_magento],
                                      login_id: session[:login_id]
                                      )
                end
            end
        end
        redirect_to finish_page_path and return
    end
    
    def finish_page
        ParserProcess.new.delay.parse_categories_attach(@login)
    end
    
    private
    
    def set_login
        @login = Login.find(session[:login_id])
    end
end
