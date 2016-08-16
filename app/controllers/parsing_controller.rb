class ParsingController < AuthenticatedController
    before_action :authenticate_vendor!
    before_filter :set_login, except: [:exists_login]
    # before_filter :activ_categories, only: [:category_product_join_table, :accepted_collection]
    before_filter :categories_group,   only: [:category_product_join_table, :accepted_collection, :accepted_collection_exists]
    
    def category
        # ParserProcess.new.delay.parse_categories(@login)
        unless Delayed::Job.count >= 1
            # ParsCategoryWorker.perform_async(@login.id)
            ParserProcess.new.delay.parse_categories(@login)
            check_categories_parsing
        else
          redirect_to in_process_path
        end
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
        # level = Category.all.map(&:level).uniq.reject{ |a| (a == 0) || (a == 1) }.sort
        # @all_categories = []
        # level.map do |a|
        #     @all_categories << { a => Category.where(level: a, is_active: 1, login_id: @login.id)}
        # end
        @collection = Collection.new
        all = []
        (1).upto(8) do |n|
            all << ShopifyAPI::CustomCollection.find(:all, params: { limit: 250, page: n })
        end
        @shopify_collect = all.flatten.uniq
    end
    
    def exists_login
        unless Delayed::Job.count >= 1
            # @login = Login.find(params[:login_id])
            @login = current_vendor.logins.where(target_url: ShopifyAPI::Shop.current.myshopify_domain).last
            Auth.shopify
            level = Category.all.map(&:level).uniq.reject{ |a| (a == 0) || (a == 1) }.sort
            @all_categories = []
            level.map do |a|
                @all_categories << { a => Category.where(level: a, is_active: 1, login_id: @login.id)}
            end
            @collection = Collection.new
            # all = []
            # (1).upto(8) do |n|
            #     all << ShopifyAPI::CustomCollection.find(:all, params: { limit: 250, page: n })
            # end
            # @shopify_collect = all.flatten.uniq
            @shopify_collect = ShopifyAPI::CustomCollection.find(:all)
        else
           redirect_to  in_process_path
        end
    end
    
    def accepted_collection
        @all_chosen_ids_for_categories = []
        @all_categories.map do |array_category|
            array_category.values[0].map do |category|
                cat_id = category.category_id
                param_shopify = "#{cat_id}_shopify_categories_ids".to_sym
                ids = params[param_shopify]
                # #include?("-1") - флаг который показывает, что категорию скипаем
                # in exist_logins we mast view last position of the where we want to import categories, that`s why we mast delete all collection
                 # "-1" -- skip, "-2" -- as parent
                unless ids.blank? || ids.include?("-2")
                    ids.map do |shopify_category_id|
                        @all_chosen_ids_for_categories << shopify_category_id
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
        unless @all_chosen_ids_for_categories.blank?
            redirect_to finish_page_path and return
        else
            redirect_to category_product_join_table_path
        end
    end
    
    def accepted_collection_exists
        Collection.where(login_id: @login.id).delete_all
        
        
        
        level = Category.all.map(&:level).uniq.reject{ |a| (a == 0) || (a == 1) }.sort
        @all_categories = []
        level.map do |a|
            @all_categories << { a => Category.where(level: a, is_active: 1, login_id: @login.id)}
        end
        @all_chosen_ids_for_categories = []
        @all_categories.map do |array_category|
            array_category.values[0].map do |category|
                cat_id = category.category_id
                param_shopify = "#{cat_id}_shopify_categories_ids".to_sym
                ids = params[param_shopify]
                # #include?("-1") - флаг который показывает, что категорию скипаем
                # in exist_logins we mast view last position of the where we want to import categories, that`s why we mast delete all collection
                 # "-1" -- skip, "-2" -- as parent
                unless ids.blank? || ids.include?("-2")
                    ids.map do |shopify_category_id|
                        @all_chosen_ids_for_categories << shopify_category_id
                        param_magento = "#{cat_id}_magento_category_id".to_sym
                        # exist_collection = Collection.where(
                        #                                       shopify_category_id:  shopify_category_id,
                        #                                       magento_category_id: params[param_magento],
                        #                                       login_id: @login.id
                        #                                       )
                        
                            Collection.create(
                                              shopify_category_id:  shopify_category_id,
                                              magento_category_id: params[param_magento],
                                              login_id: @login.id
                                              )
                    end
                end
            end
        end
        unless @all_chosen_ids_for_categories.blank?
            redirect_to finish_page_path and return
        else
            redirect_to category_product_join_table_path
        end
    end
    
    def in_process
    end
    
    def finish_page
        unless Delayed::Job.count >= 1
            vendor_id = Session.find_by(session_id: session.id).data['warden.user.vendor.key'][0][0]
            @login = Login.where(vendor_id: vendor_id).last
            ParserProcess.new.delay.parse_categories_attach_and_create_objects(@login)
            # ParsAttachWorker.perform_async(@login.id)
        else
           redirect_to  in_process_path
        end
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
        @login = Login.find(current_vendor.logins.last.id)
    end
end
