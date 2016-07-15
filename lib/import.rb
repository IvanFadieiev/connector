module Import
    class CreateCategories < AuthenticatedController
        extend ShopSession
        def create(login)
            # # # # delete
            # login = Login.find(259)
            CreateCategories.new_with(login)
            categories_for_creating = Collection.where( login_id: login.id, shopify_category_id: 0 )
            if categories_for_creating.any?
                categories_for_creating.map do |category|
                    # data = SmarterCSV.process("public/#{login.id}/categories/categories.csv")
                    # data = Category.where(login_id: login.id)
                    # find_category = []
                    # data.map{ |a| find_category << a if ( a.category_id == category.magento_category_id ) }
                    find_category = Category.where("login_id == ? and category_id == ? ", login.id, category.magento_category_id)
                    title = find_category[0][:name]
                    unless find_category[0][:description].include?("{")
                        body_html = find_category[0].description
                    else
                        body_html = nil
                    end
                    src = find_category[0].image
                    
                    categ = ShopifyAPI::CustomCollection.new( @attributes={ 'title': title, 'body_html': body_html } )
                    categ.save
                    
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
        def recursive( children_categories_1_lavel, category, login, data )
            unless children_categories_1_lavel.blank?
                children_categories_2_lavel = []
                children_categories_1_lavel.uniq.map do |_1_lav_cat|
                    data.map{|a| children_categories_2_lavel << a if (a.parent_id == _1_lav_cat.category_id)}
                end
                
                # создать TargetCategoryImport для каждого из $children_categories_2_lavel
                children_categories_2_lavel.uniq.map do |children|
                    TargetCategoryImport.create( magento_category_id: children.category_id, shopify_category_id: category.shopify_category_id, login_id: login.id )
                end
                
                unless children_categories_2_lavel.blank?
                    recursive( children_categories_2_lavel, category, login, data )
                end
            end
        end
        
        def create_products_to_shop(login)
            # # # # delete
            # login = Login.find(259)
            CreateCategories.new_with(login)
            created_categories = Collection.where( login_id: login.id ).distinct
            created_categories.map do |category|
                TargetCategoryImport.create( magento_category_id: category.magento_category_id, shopify_category_id: category.shopify_category_id, login_id: login.id )
                
                # data = SmarterCSV.process("public/#{login.id}/categories/categories.csv")
                # data = Category.where(login_id: login.id)
                # $children_categories_1_lavel = []
                # data.map{|a| $children_categories_1_lavel << a if (a.parent_id == category.magento_category_id)}
                $children_categories_1_lavel = Category.where('login_id == ? and parent_id == ?', login.id, category.magento_category_id )
                data = $children_categories_1_lavel
                # создать TargetCategoryImport для каждой дочерней категории
                $children_categories_1_lavel.map do |children|
                    TargetCategoryImport.create( magento_category_id: children.category_id, shopify_category_id: category.shopify_category_id, login_id: login.id )
                end
                
                recursive( $children_categories_1_lavel, category, login, data )
    
            end
            create_products(login)
        end
        
        def create_products(login)
            # data         = SmarterCSV.process("public/#{login.id}/categories_products/join_table_categories_products.csv")
            # all_products = SmarterCSV.process("public/#{login.id}/products/products_table.csv")
            # images       = SmarterCSV.process("public/#{login.id}/image/products/join_table_products_images_table.csv")
            # data         = JoinTableCategoriesProduct.where(login_id: login.id).uniq
            # TargetCategoryImport.where(login_id: login.id).distinct.find_each.lazy do |cat|
            #     magento_id = cat.magento_category_id
                Product.includes(:images, :magento_categories).where(login_id: login.id).distinct.find_each.lazy do |product|
                    if product.status == "1"
                        title     = product.name
                        unless product.description.include?("{:\"@xsi:type\"")
                            body_html = product.description
                        else
                            body_html = ""
                        end
                        handle = producte.url_key
                        sku    = product.sku
                        unless (product.price == nil)
                            price  = product.price.to_i
                        else
                            price = 0
                        end
                        status = product.status
                        
                        shop_product = ShopifyAPI::Product.new( @attributes={ 'title': title, 'body_html': body_html, 'handle': handle } )
                        
                        shop_product.save
                        id = shop_product.id
                        p  "_______!!!!!!!!_______!!!!!!!!!!!!!Product ID: #{id} CREATED!!!!!!!!_______!!!!!!!!!!!!!__________"
                        ip = ShopifyAPI::Product.find(id)
                        
                        images_for_product = product.images
                        unless images_for_product.blank?
                            images_for_product.map do |image_line|
                                begin
                                    src = image_line.image_url
                                    ip.images << { 'src': src }
                                    ip.save
                                rescue
                                    p "Image not found"
                                end
                            end
                        end
                        ip.variants.first.update_attributes('sku': sku)
                        ip.variants.first.update_attributes('price': price)
                        
                        product.magento_categories.distinct.each do |cat|
                            shop_cat = cat.target_category_import.shopify_category_id
                            ShopifyAPI::Collect.create({"collection_id": shop_cat, "product_id": id})
                        end
                        sleep 2
                    end
                end
            # end
            # all_products = Product.where(login_id: login.id, status: "1").uniq
            # images       = ProductImage.where(login_id: login.id).uniq
            # TargetCategoryImport.where(login_id: login.id).map do |cat|
            #     $prod_object_for_cat = []
            #     prod_ids_for_category = []
            #     magento_id = cat.magento_category_id
            #     # shopify_id = cat.shopify_category_id
            #     data.map do |line|
            #         prod_ids_for_category << line if ( line.category_id == magento_id )
            #     end
            #     prod_ids_for_category.map do |prod|
            #         all_products.map do |line_prod|
            #             $prod_object_for_cat << line_prod if (line_prod.product_id == prod.product_id)
            #         end
            #     end
            #     $prod_object_for_cat.map do |product_line|
                    
            #         title     = product_line.name
            #         unless product_line.description.include?("{:\"@xsi:type\"")
            #             body_html = product_line.description
            #         else
            #             body_html = ""
            #         end
            #         handle = product_line.url_key
            #         sku    = product_line.sku
            #         unless (product_line.price == nil)
            #             price  = product_line.price
            #         else
            #             price = 0
            #         end
            #         status = product_line.status
                    
            #         product = ShopifyAPI::Product.new( @attributes={ 'title': title, 'body_html': body_html, 'handle': handle } )
                    
            #         product.save
            #         id = product.id
            #         p  "#{product.id} CREATED!!!!!!!!_______!!!!!!!!!!!!!__________"
            #         ip = ShopifyAPI::Product.find(id)
                    
            #         # images_for_product = []
            #         # images.map do |img|
            #         #   images_for_product << img if (img.product_id == product_line.product_id) 
            #         # end
            #         images_for_product = product_line.product_images
            #         unless images_for_product.blank?
            #             images_for_product.map do |image_line|
            #                 begin
            #                     src = image_line.image_url
            #                     ip.images << { 'src': src }
            #                     ip.save
            #                 rescue
            #                     p "Image not found"
            #                 end
            #             end
            #         end
            #         ip.variants.first.update_attributes('sku': sku)
            #         ip.variants.first.update_attributes('price': price)
                    
                    
            #         ShopifyAPI::Collect.create({"collection_id": cat.shopify_category_id , "product_id": id})
                    
            #         sleep 2
            #     end
            # end
        end
    end
    ShopifyAPI::Base.clear_session
end



