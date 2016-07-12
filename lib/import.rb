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
        def recursive( children_categories_1_lavel, data, category, login )
            unless children_categories_1_lavel.blank?
                children_categories_2_lavel = []
                children_categories_1_lavel.map do |_1_lav_cat|
                    data.map{|a| children_categories_2_lavel << a if (a[:parent_id]== _1_lav_cat[:category_id])}
                end
                
                # создать TargetCategoryImport для каждого из $children_categories_2_lavel
                children_categories_2_lavel.map do |children|
                    TargetCategoryImport.create( magento_category_id: children[:category_id], shopify_category_id: category.shopify_category_id, login_id: login.id )
                end
                
                unless children_categories_2_lavel.blank?
                    recursive( children_categories_2_lavel, data, category, login )
                end
            end
        end
        
        def create_products_to_shop(login)
            # # # # delete
            login = Login.find(259)
            
            CreateCategories.new_with(login)
            created_categories = Collection.where( login_id: login.id )
            created_categories.map do |category|
                TargetCategoryImport.create( magento_category_id: category.magento_category_id, shopify_category_id: category.shopify_category_id, login_id: login.id )
                
                data = SmarterCSV.process("public/#{login.id}/categories/categories.csv")
                $children_categories_1_lavel = []
                data.map{|a| $children_categories_1_lavel << a if (a[:parent_id]== category.magento_category_id)}
                # создать TargetCategoryImport для каждой дочерней категории
                $children_categories_1_lavel.map do |children|
                    TargetCategoryImport.create( magento_category_id: children[:category_id], shopify_category_id: category.shopify_category_id, login_id: login.id )
                end
                
                recursive( $children_categories_1_lavel, data, category, login )
                
            end
        end
        
        def create_products(login)
            byebug
        end
    end
    ShopifyAPI::Base.clear_session
end



