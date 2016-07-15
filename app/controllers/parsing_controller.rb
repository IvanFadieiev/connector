class ParsingController < AuthenticatedController
    before_filter :set_login
    # before_filter :activ_categories, only: [:category_product_join_table, :accepted_collection]
    
    def category
        
        # ParserProcess.new.delay.parse_categories(@login)
        ParsCategoryWorker.perform_async(@login.id)
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
        @all_categories = Category.where('level == 2 and is_active == 1 and login_id == ?', @login.id)
        @collection = Collection.new
        @shopify_collect = ShopifyAPI::CustomCollection.all
    end
    
    def accepted_collection
        @all_categories = Category.where('level == 2 and is_active == 1 and login_id == ?', @login.id)
        @all_categories.map do |category|
            cat_id = category.category_id
            param_shopify = "#{cat_id}_shopify_categories_ids".to_sym
            ids = params[param_shopify]
            unless ids.blank?
                ids.map do |shopify_category_id|
                    param_magento = "#{cat_id}_magento_category_id".to_sym
                    Collection.create(
                                      shopify_category_id:  shopify_category_id,
                                      magento_category_id: params[param_magento],
                                      login_id: @login.id
                                      )
                end
            end
        end
        redirect_to finish_page_path and return
    end
    
    def finish_page
        # ParserProcess.new.delay.parse_categories_attach_and_create_objects(@login)
        ParsAttachWorker.perform_async(@login.id)
    end
    
    private
    
    def set_login
        @login = Login.find(session[:login_id])
        # @login = Login.find(451)
    end
end
