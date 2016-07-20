class ParsingController < AuthenticatedController
    before_filter :set_login
    # before_filter :activ_categories, only: [:category_product_join_table, :accepted_collection]
    # before_filter :categories_group,   only: [:category_product_join_table, :accepted_collection]
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
        level = Category.all.map(&:level).uniq.reject{ |a| (a == 0) || (a == 1) }.sort
        @all_categories = []
        level.map do |a|
            @all_categories << { a => Category.where(level: a, is_active: 1, login_id: @login.id)}
        end
        @collection = Collection.new
        @shopify_collect = ShopifyAPI::CustomCollection.all
    end
    
    def accepted_collection
        level = Category.all.map(&:level).uniq.reject{ |a| (a == 0) || (a == 1) }.sort
        @all_categories = []
        level.map do |a|
            @all_categories << { a => Category.where(level: a, is_active: 1, login_id: @login.id)}
        end
        @all_categories.map do |array_category|
            array_category.values[0].map do |category|
                
                # category.update_attributes(chosen: true)
                
                cat_id = category.category_id
                param_shopify = "#{cat_id}_shopify_categories_ids".to_sym
                ids = params[param_shopify]
                # #include?("-1") - флаг который показывает, что категорию скипаем
                unless ids.blank? || ids.include?("-1")
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
        end
        redirect_to finish_page_path and return
    end
    
    def finish_page
        # ParserProcess.new.delay.parse_categories_attach_and_create_objects(@login)
        ParsAttachWorker.perform_async(@login.id)
    end
    
    private
    
    def categories_group
        level = Category.all.map(&:level).uniq.reject{ |a| (a == 0) || (a == 1) }.sort
        @all_categories = []
        level.map do |a|
            @all_categories << { a => Category.where(level: a, is_active: 1, login_id: @login.id)}
        end
    end
    
    def set_login
        @login = Login.find(session[:login_id])
        # @login = Login.find(451)
    end
end
