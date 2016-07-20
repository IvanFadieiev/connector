module Import
    class CreateCategories < AuthenticatedController
        extend ShopSession
        def create(login)
            #
            # Выгребаем категории для создания (с shopify_category_id: 0) и содаем такую же в Shopify, потом апдейтим ее shopify_category_id на тот, который 
            #
            CreateCategories.new_with(login)
            categories_for_creating = Collection.where( login_id: login.id, shopify_category_id: 0 )
            if categories_for_creating.any?
                categories_for_creating.map do |category|
                    find_category = Category.where("login_id LIKE ? AND category_id LIKE ? ", login.id, category.magento_category_id)
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
                    p "#{categ} CATEGORY CRATED!!!"
                    category.update_column(:shopify_category_id, categ.id)
                    
                end
            end
        end
        
        def category_tree(magento_category_id, login)
            category = Category.find_by(category_id: magento_category_id, login_id: login.id)
            @category_tree = []
            recursive_category_tree(category.category_id, login)
            @category_tree
        end
          
        def recursive_category_tree(category, login)
            acategory = Category.find_by(category_id: category, login_id: login.id)
            @category_tree << acategory
            Category.where(parent_id: category, login_id: login.id).map do |cat|
                @category_tree << cat
                childrens = Category.where(parent_id: cat.category_id, login_id: login.id)
                unless childrens.blank?
                    childrens.map do |sub|
                        recursive_category_tree(sub.category_id, login)
                    end
                end
            end
        end
    end
    
    class   CreateProducts < AuthenticatedController
        # def recursive( children_categories_1_lavel, category, login, data )
        #     ids = Collection.where(login_id: login.id).map(&:magento_category_id)
        #     unless children_categories_1_lavel.blank?
        #         children_categories_2_lavel = []
        #         children_categories_1_lavel.uniq.map do |_1_lav_cat|
        #             data.map{|a| children_categories_2_lavel << a if (a.parent_id == _1_lav_cat.category_id)}
        #         end
                
        #         # создать TargetCategoryImport для каждого из $children_categories_2_lavel
        #         unless children_categories_2_lavel.blank?
        #             children_categories_2_lavel.uniq.map do |children|
        #                 unless ids.include?(category.magento_category_id)
        #                     TargetCategoryImport.create( magento_category_id: children.category_id, shopify_category_id: category.shopify_category_id, login_id: login.id )
        #                 end
        #             end
        #         end
        #         unless children_categories_2_lavel.blank?
        #             recursive( children_categories_2_lavel, category, login, data )
        #         end
        #     end
        # end
        
        # def create_products_to_shop(login)
        #     CreateCategories.new_with(login)
        #     ids = Collection.where(login_id: login.id).map(&:magento_category_id)
        #     created_categories = Collection.where( login_id: login.id ).order('id DESC').distinct
        #     created_categories.map do |category|
        #         TargetCategoryImport.create( magento_category_id: category.magento_category_id, shopify_category_id: category.shopify_category_id, login_id: login.id )
        #         $children_categories_1_lavel = Category.where(login_id: login.id, parent_id: category.magento_category_id )
        #         data = $children_categories_1_lavel
        #         # создать TargetCategoryImport для каждой дочерней категории
        #         $children_categories_1_lavel.map do |children|
        #             unless ids.include?(category.magento_category_id)
        #                 TargetCategoryImport.create( magento_category_id: children.category_id, shopify_category_id: category.shopify_category_id, login_id: login.id )
        #             end
        #         end
                
        #         recursive( $children_categories_1_lavel, category, login, data )
    
        #     end
        #     create_products(login)
        # end
        
        
        def create_products_to_shop(login)
            categories_tree = Parser::ProductList.new.array_of_categories_tree(login)
            categories_tree.map do |category_tree_ids|
                target = Collection.find_by(magento_category_id: category_tree_ids[0], login_id: login.id)
                category_tree_ids.each do |id|
                    TargetCategoryImport.create( magento_category_id: id, shopify_category_id: target.shopify_category_id, login_id: login.id )
                    p 'target created'
                end
            end
            # create_products(login)
        end
        
        def create_products(login)
            $error_prod = []
            Product.includes(:images, :magento_categories).where(login_id: login.id).uniq.map do |product|
                
                # params for product
                unless product.description.include?("{:\"@xsi:type\"")
                    body_html = product.description
                else
                    body_html = ""
                end
                unless (product.price == nil)
                    price = product.price.to_i
                else
                    price = 0
                end
                handle        = product.url_key
                sku           = product.sku
                title      = product.name
                barcode       = product.ean
                status        = product.status
                weight        = product.weight
                special_price = product.special_price
# это для обновления продукта                
                # exist_products = ShopifyAPI::Variant.where( sku: product.sku )
                
                # if exist_products.blank?
                    if product.shopify_product_id.blank?
                        # title     = product.name
                        # unless product.description.include?("{:\"@xsi:type\"")
                        #     body_html = product.description
                        # else
                        #     body_html = ""
                        # end
                        # handle = product.url_key
                        # sku    = product.sku
                        # unless (product.price == nil)
                        #     price  = product.price.to_i
                        # else
                        #     price = 0
                        # end
                        # barcode       = product.ean
                        # status        = product.status
                        # weight        = product.weight
                        # special_price = product.special_price
                        
                        if status == "1"
                            shop_product = ShopifyAPI::Product.new( @attributes={ 'title': title, 'body_html': body_html, 'handle': handle } )
                        else
                            shop_product = ShopifyAPI::Product.new( @attributes={ 'title': title, 'body_html': body_html, 'handle': handle, "published_scope": "global", "published_at": nil, "published_status": "published" } )
                        end
                        shop_product.save
                        id = shop_product.id
                        p  "ADD PRODUCT: #{id}"
                        # Product.find(product.id).update_column(:shopify_product_id, id)
                        ip = ShopifyAPI::Product.find(id)
                        images_for_product = product.images
                        unless images_for_product.blank?
                            images_for_product.map do |image_line|
                                begin
                                    src = image_line.img_url
                                    ip.images << { 'src': src }
                                    ip.save
                                rescue
                                    p "Image not found"
                                end
                            end
                        end
                        if special_price == nil
                            ip.variants.first.update_attributes( 'sku': sku, 'price': price, 'barcode': barcode, 'weight': weight )
                        else
                            ip.variants.first.update_attributes( 'sku': sku, 'price': special_price, 'compare_at_price': price, 'barcode': barcode, 'weight': weight )
                        end
                        product.magento_categories.where(login_id: login.id).group(:category_id).distinct.map do |cat|
                            unless cat.target_category_import.blank?
                                shop_cat = cat.target_category_import.where(login_id: login.id).last.shopify_category_id
                                ShopifyAPI::Collect.create({"collection_id": shop_cat, "product_id": id})
                                p "Prod #{id} add to cat: #{shop_cat}"
                            end
                        end
                        product.update_column(:shopify_product_id, id)
                    end
                    
# это для обновления продукта

                # else
                #     exist_products.map do |a|
                #         if special_price == nil
                #             a.update_attributes( 'price': price )
                #         else
                #             a.update_attributes( 'price': special_price, 'compare_at_price': price )
                #         end
                #     end
                # end
            end
        end
    end
end
