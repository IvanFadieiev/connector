module Import
    class CreateCategories < AuthenticatedController
        extend ShopSession
        def create(login)
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
    
    # class   CreateProducts < AuthenticatedController
    #     def recursive(login,id)
    #         data = SmarterCSV.process("public/#{login.id}/categories/categories.csv")
    #         data.map{|a| $children_categories << a if (a[:parent_id]==id)}
    #         $children_categories.map do |cat|
    #             id_cat = cat[:category_id]
    #             recursive(login, id_cat)
    #         end
    #         $children_categories
    #         create_products(login)
    #     end
        
    #     def create_products_to_shop(login)
    #         byebug
    #         created_categories = Collection.where( login_id: login.id )
    #         created_categories.first do |category|
    #             $children_categories = []
    #             recursive(login, category.magento_category_id)
    #         end
    #     end
        
    #     def create_products(login)
    #         byebug
    #     end
    # end
    ShopifyAPI::Base.clear_session
end



