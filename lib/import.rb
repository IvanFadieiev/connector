module Import
    class CreateCategories < AuthenticatedController
        extend ShopSession
        def create(login)
            # # # # delete
            login = Login.find(259)
            CreateCategories.new_with(login)
            categories_for_creating = Collection.where( login_id: login.id, shopify_category_id: 0 )
            if categories_for_creating.any?
                categories_for_creating.map do |category|
                    # # найти категорию:
                    data = SmarterCSV.process("public/#{login.id}/categories/categories.csv")
                    find_category = []
                    data.map{ |a| find_category << a if ( a[:category_id] == category.magento_category_id ) }
                    title = find_category[0][:name]
                    unless find_category[0][:description].class == Hash 
                        body_html = find_category[0][:description]
                    else
                        body_html = nil
                    end
                    src = find_category[0][:image]
                    
                    # # создать категорию
                    categ = ShopifyAPI::CustomCollection.new( @attributes={ 'title': title, 'body_html': body_html } )
                    categ.save
                    
                    # # найти и создать картинку для категории
                    unless src.blank? && src.class != Hash
                        img_cat = ShopifyAPI::CustomCollection.find(categ.id)
                        img_cat.image = { 'src': "#{login.store_url}/media/catalog/category/#{src}" }
                        img_cat.save
                    end
                    p "#{categ} CRATED!!!"
                    category.update_column(:shopify_category_id, categ.id)
                    
                end
            end
        end
    end
    
    class   CreateProducts < AuthenticatedController
        def recursive(login,id)
            data = SmarterCSV.process("public/#{login.id}/categories/categories.csv")
            data.map{|a| $children_categories << a if (a[:parent_id]==id)}
            $children_categories.map do |cat|
                id_cat = cat[:category_id]
                recursive(login, id_cat)
            end
            $children_categories
            create_products(login)
        end
        
        def create_products_to_shop(login)
            # # # # delete
            login = Login.find(259)
            
            CreateCategories.new_with(login)
            created_categories = Collection.where( login_id: login.id )
            created_categories.map do |category|
                # создать товар в шопифай!!!!!!!!!!!!!!!!!!!!
                TargetCategoryImport.create( magento_category_id: category.magento_category_id, shopify_category_id: category.shopify_category_id, login_id: login.id, )
                # children_category_1_lavel
                $children_categories_1_lavel = []
                # recursive(login, category.magento_category_id)
                data = SmarterCSV.process("public/#{login.id}/categories/categories.csv")
                data.map{|a| $children_categories_1_lavel << a if (a[:parent_id]== category.id)}
                # создать TargetCategoryImport для каждого из  $children_categories_1_lavel
                # - // -
                    $children_categories_2_lavel = []
                    $children_categories_1_lavel.map do |1_lav_cat|
                        data.map{|a| $children_categories_2_lavel << a if (a[:parent_id]== 1_lav_cat[:category_id])}
                    end
                    # создать TargetCategoryImport для каждого из $children_categories_2_lavel
                    $children_categories_3_lavel = []
                    $children_categories_2_lavel.map do |2_lav_cat|
                        data.map{|a| $children_categories_3_lavel << a if (a[:parent_id]== 2_lav_cat[:category_id])}
                    end
                     # создать TargetCategoryImport для каждого из $children_categories_3_lavel
                    $children_categories_4_lavel = []
                    $children_categories_3_lavel.map do |3_lav_cat|
                        data.map{|a| $children_categories_4_lavel << a if (a[:parent_id]== 3_lav_cat[:category_id])}
                    end
                     # создать TargetCategoryImport для каждого из $children_categories_4_lavel
                byebug
                
            end
        end
        
        def create_products(login)
            byebug
        end
    end
    ShopifyAPI::Base.clear_session
end



