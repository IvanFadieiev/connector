module Import
    class CreateCategories < AuthenticatedController
        # extend ShopSession
        def create(login)
            #
            # Выгребаем категории для создания (с shopify_category_id: 0) и содаем такую же в Shopify, потом апдейтим ее shopify_category_id на тот, который
            Auth.shopify
            
            categories_for_creating = Collection.where( login_id: login.id, shopify_category_id: 0 )
            if categories_for_creating.any?
                categories_for_creating.map do |category|
                    find_category = Category.where("login_id LIKE ? AND category_id LIKE ? ", login.id, category.magento_category_id)
        			client  = Savon.client( wsdl: login.store_url + '/api/?wsdl' )
        			request = client.call( :login, message:{ magento_username: login.username, key: login.key})
        			session = request.body[:login_response][:login_return]
    				if find_category[0].description == nil
    					response = client.call(:call){message(:session => session, :method=> 'catalog_category.info', categoryId: category.magento_category_id)}.body[:call_response][:call_return][:item]
    					desc = []
    					response.map{|a| desc << a if (a[:key] == 'description')}
    					description = desc[0][:value]
    					img = []
    					response.map{|a| img << a if (a[:key] == 'image')}
    					image = img[0][:value]
    					find_category[0].update_attributes( description: description, image: image )
    				end
                    title = find_category[0][:name]
                    begin
                        unless find_category[0][:description] == nil
                            unless find_category[0][:description].include?("{")
                                body_html = find_category[0].description
                            else
                                body_html = ""
                            end
                        else
                             body_html = ""
                        end
                    rescue => e
                        p "#{e}"
                        body_html = ""
                    end
                    src = find_category[0].image
                    begin
                        categ = ShopifyAPI::CustomCollection.new( @attributes={ 'title': title, 'body_html': body_html } )
                    rescue
                        Auth.shopify
                        categ = ShopifyAPI::CustomCollection.new( @attributes={ 'title': title, 'body_html': body_html } )
                    end
                    categ.save
                    unless src.blank? && src.class != Hash
                        begin
                            img_cat = ShopifyAPI::CustomCollection.find(categ.id)
                        rescue    
                            Auth.shopify
                            img_cat = ShopifyAPI::CustomCollection.find(categ.id)
                        end
                        img_cat.image = { 'src': "#{login.store_url}/media/catalog/category/#{src}" }
                        img_cat.save
                    end
                    p "#{categ} CATEGORY CRATED!!!"
                    category.update_attributes(shopify_category_id: categ.id)
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
            if acategory.is_active == "1"
                @category_tree << acategory
            end
            Category.where(parent_id: category, login_id: login.id).map do |cat|
                if cat.is_active == "1"
                    @category_tree << cat
                end
                childrens = Category.where(parent_id: cat.category_id, login_id: login.id, is_active: "1")
                unless childrens.blank?
                    childrens.map do |sub|
                        recursive_category_tree(sub.category_id, login)
                    end
                end
            end
        end
    end
    
    class   CreateProducts < AuthenticatedController
        def create_products_to_shop(login)
            categories_tree = Parser::ProductList.new.array_of_categories_tree(login)
            categories_tree.map do |category_tree_ids|
                target = Collection.find_by(magento_category_id: category_tree_ids[0], login_id: login.id)
                category_tree_ids.each do |id|
                    if TargetCategoryImport.find_by( magento_category_id: id, shopify_category_id: target.shopify_category_id, login_id: login.id ).blank?
                        TargetCategoryImport.create( magento_category_id: id, shopify_category_id: target.shopify_category_id, login_id: login.id )
                    end
                    cat_for_monitoring = CategoryForMonitoring.where(magento_category_id: id, shopify_category_id: target.shopify_category_id, shopify_domain: login.target_url)
                    if cat_for_monitoring.blank?
                        CategoryForMonitoring.create(magento_category_id: id, shopify_category_id: target.shopify_category_id, shopify_domain: login.target_url)
                    end
                    p 'target created'
                end
            end
            create_products(login)
        end
        
        def create_products(login)
            $error_prod = []
            Product.includes(:images, :magento_categories).where("login_id LIKE ? and status = 1 and prod_type = 'configurable'", login.id ).uniq.map do |product|
                simples = []
                product.product_simples.where(login_id: login.id).map{|a| simples << a if (a.qty > 0)}
                unless simples.blank?
                    begin
                        # params for product
                        begin
                            unless product.description == nil
                                unless product.description.include?("{")
                                    body_html = product.description
                                else
                                    body_html = ""
                                end
                            end
                        rescue => e
                            p "#{e}"
                            body_html = ""
                        end
                        unless (product.price == nil)
                            price = product.price.to_i
                        else
                            price = 0
                        end
                        handle        = product.url_key
                        sku           = product.sku
                        title         = product.name
                        barcode       = product.ean
                        status        = product.status
                        weight        = product.weight
                        special_price = product.special_price.to_i
                        qty           = product.qty.to_s
                        # для обновления продукта
                        begin
                            exist_products =  ShopifyAPI::Product.find(:all, :params => {'title': title })
                        rescue
                             Auth.shopify
                            
                            exist_products =  ShopifyAPI::Product.find(:all, :params => {'title': title })
                        end
                        
                        if exist_products.blank?
                            if product.shopify_product_id.blank?
    
                                if status == "1"
                                    counter = login.counter + 1
                                    login.update_attributes( counter: counter )
                                    begin
                                        shop_product = ShopifyAPI::Product.new( @attributes={ 'title': title, 'body_html': body_html, 'handle': handle, options: [{name: "Size"}] } )
                                    rescue
                                        Auth.shopify
                                        shop_product = ShopifyAPI::Product.new( @attributes={ 'title': title, 'body_html': body_html, 'handle': handle, options: [{name: "Size"}] } )
                                    end
                                else
                                    counter = login.counter + 1
                                    login.update_attributes( counter: counter )
                                    begin
                                        shop_product = ShopifyAPI::Product.new( @attributes={ 'title': title, 'body_html': body_html, 'handle': handle, "published_scope": "global", "published_at": nil, "published_status": "published", options: [{name: "Size"}] } )
                                        counter = login.counter + 1
                                        login.update_attributes( counter: counter )
                                    rescue
                                        Auth.shopify
                                        shop_product = ShopifyAPI::Product.new( @attributes={ 'title': title, 'body_html': body_html, 'handle': handle, "published_scope": "global", "published_at": nil, "published_status": "published", options: [{name: "Size"}] } )
                                        counter = login.counter + 1
                                        login.update_attributes( counter: counter )
                                    end
                                end
                                shop_product.save
                                id = shop_product.id
                                p  "ADD PRODUCT: #{id}"
                                begin
                                    ip = ShopifyAPI::Product.find(id)
                                rescue
                                    Auth.shopify
                                    ip = ShopifyAPI::Product.find(id)
                                end
                            # images for product
                                begin
                    				arrr = $client.call(:call){ message( session:   $session,
                    												     method:    'catalog_product_attribute_media.list',
                    											         productId: product.product_id
                    													 )
                    											}.body[:call_response][:call_return][:item]
                    			rescue => e
                    			    p e
                    			    Parser::Login.new.login(login)
                    			    arrr = $client.call(:call){ message( session:   $session,
                    												     method:    'catalog_product_attribute_media.list',
                    											         productId: product.product_id
                    													 )
                    											}.body[:call_response][:call_return][:item]
                    			end
                				images  = []
                				if arrr.class == Hash
                					arrr[:item].map{ |a| images << a[:value] if (a[:key] == "url") } 
                				else
                					unless arrr == nil
                						arrr.map do |a| 
                							a[:item].map do |b|
                								images << b[:value] if ((b[:key] == "url") )
                							end
                						end
                					end
                				end
                				if images.any?
                					images.map do |img_url|
                						$error2 = []
                						begin
                						unless img_url.blank?
                							begin
                								open(img_url)
                                                begin
                                                    ip.images << { 'src': img_url }
                                                    ip.save
                                                rescue
                                                    p "Image not found"
                                                end        								
                								p "Image for Product add to table #{img_url}"
                							rescue
                							 p 'don`t valid uri for image'	
                							end
                						else
                							p "Product with ID: #{product_id} havn`t image"
                						end
                						rescue
                							$error2 << img_url
                							p '-----------------------Error($error2)---------------------------'
                						end
                					end
                				end                        
                                
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
                                
                            
                                if simples.count >  1
                                    simples.map do |simple|
                                        if simple.length
                                            option = "#{simple.size } x #{simple.length}"
                                        else
                                            option = simple.size
                                        end
                                        if simple.qty != 0
                                            if product.special_price == nil
                                                ip.variants << ShopifyAPI::Variant.new(
                                                    :sku => simple.sku,
                                                    :price => product.price.to_i,
                                                    :barcode => product.ean,
                                                    :weight => product.weight,
                                                    :inventory_policy => "continue",
                                                    :inventory_management => "shopify",
                                                    :inventory_quantity => simple.qty,
                                                    :option1 => option
                                                )
                                                p 'add variant'
                                                ip.save
                                            else
                                                ip.variants << ShopifyAPI::Variant.new(
                                                    :sku => simple.sku,
                                                    :price =>  product.special_price.to_i,
                                                    :compare_at_price => product.price.to_i,
                                                    :barcode => product.ean,
                                                    :weight => product.weight,
                                                    :inventory_policy => "continue",
                                                    :inventory_management => "shopify",
                                                    :inventory_quantity => simple.qty,
                                                    :option1 => option
                                                )
                                                p 'add variant'
                                                ip.save
                                            end
                                            simple.update_attributes(shopify_product_id: ip.variants.last.id)
                                        end
                                    end
                                    ip.variants.first.destroy if ip.variants.count > 2
                                else
                                    if product.special_price == nil
                                        ip.variants.first.update_attributes( 'sku': product.sku, 'price': product.price.to_i, 'barcode': product.ean, 'weight': product.weight, "inventory_policy": "continue", "inventory_management": "shopify", 'inventory_quantity': simples[0].qty, 'option1': simples[0].size )
                                    else
                                        ip.variants.first.update_attributes( 'sku': product.sku, 'price': product.special_price.to_i, 'compare_at_price': product.price.to_i, 'barcode': product.ean, 'weight': product.weight, 'inventory_quantity': simples[0].qty, "inventory_policy": "continue", "inventory_management": "shopify", 'option1': simples[0].size )
                                    end
                                end
                                
                                
                                product.magento_categories.where(login_id: login.id).group(:category_id).distinct.map do |cat|
                                    unless cat.target_category_import.blank?
                                        shop_cat = cat.target_category_import.where(login_id: login.id).last.shopify_category_id
                                        begin
                                            if ShopifyAPI::Collect.find(:all, :params => {"collection_id": shop_cat, "product_id": id}).blank?
                                                ShopifyAPI::Collect.create({"collection_id": shop_cat, "product_id": id})
                                                p "Prod #{id} add to cat: #{shop_cat}"
                                            end
                                        rescue
                                            Auth.shopify
                                            if ShopifyAPI::Collect.find(:all, :params => {"collection_id": shop_cat, "product_id": id}).blank?
                                                ShopifyAPI::Collect.create({"collection_id": shop_cat, "product_id": id})
                                                p "Prod #{id} add to cat: #{shop_cat}"
                                            end                                            
                                        end
                                    end
                                end
                                if ip.images.blank?
                                    title = ip.title
                                    begin
                                        prod = ShopifyAPI::Product.find(:all, :params => {'title': title })
                                        prod.destroy
                                        p 'product destroyed'
                                    rescue
                                        Auth.shopify
                                        prod = ShopifyAPI::Product.find(:all, :params => {'title': title })
                                        prod.destroy
                                        p 'product destroyed'
                                    end
                                end
                                product.update_attributes(shopify_product_id: id)
                            end
                            
                        #обновления продукта
                        else
                            exist_products.map do |a|
                                if product.special_price == nil
                                    counter = login.counter + 1
                                    login.update_attributes( counter: counter )
                                    a.variants.map{|p| p.update_attributes( 'price': product.price.to_i )}
                                    p 'product updated +++'
                                else
                                    counter = login.counter + 1
                                    login.update_attributes( counter: counter )
                                    a.variants.map{|p| p.update_attributes( 'price': product.special_price.to_i, 'compare_at_price': product.price.to_i )}
                                    p 'product updated +++'
                                end
                                product.magento_categories.where(login_id: login.id).group(:category_id).distinct.map do |cat|
                                    unless cat.target_category_import.blank?
                                        shop_cat = cat.target_category_import.where(login_id: login.id).last.shopify_category_id
                                        begin
                                             if ShopifyAPI::Collect.find(:all, :params => {"collection_id": shop_cat, "product_id": id}).blank?
                                                ShopifyAPI::Collect.create({"collection_id": shop_cat, "product_id": a.id})
                                                p "Prod #{a.id} add to cat: #{shop_cat} +"
                                             end
                                        rescue
                                            Auth.shopify
                                            
                                            if ShopifyAPI::Collect.find(:all, :params => {"collection_id": shop_cat, "product_id": id}).blank?
                                                ShopifyAPI::Collect.create({"collection_id": shop_cat, "product_id": a.id})
                                                p "Prod #{a.id} add to cat: #{shop_cat} +"
                                            end                                            
                                        end
                                    end
                                end
                                if a.images.blank?
                                    title = a.title
                                    begin
                                        prod = ShopifyAPI::Product.find(:all, :params => {'title': title }).last
                                        prod.destroy
                                        p 'product destroyed'
                                    rescue
                                        Auth.shopify
                                        prod = ShopifyAPI::Product.find(:all, :params => {'title': title }).last
                                        prod.destroy
                                        p 'product destroyed'
                                    end
                                end
                                sleep 0.5
                            end
                        end
                    rescue => error
                        p "Error with update product! Error: #{error}"
                    end
                end
            end
        end
    end
    
    class Reconnect
        def self.new_with(login)
             Auth.shopify
        end
    end
end
