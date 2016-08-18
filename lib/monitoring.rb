module Monitoring
    class Product_in_magento_shop
    	def create_join_table_categories_products
    		$array_cat = []
    		monitored_cat = CategoryForMonitoring.all.map(&:magento_category_id).uniq
    		unless monitored_cat.blank?
    		    monitored_cat.each do |cat_id|
        			p "Parsed category #{ cat_id }"
        			category_products( cat_id )
        			check_nil( $products_to_category, cat_id )
        		end
        	end
    	end
    	
    	def category_products( id )
			begin
				$products_to_category = $client.call(:call){ message( session: $session,
																	  method: 'catalog_category.assignedProducts',
																	  categoryId: id
																	  )
													}.body[:call_response][:call_return][:item]
			rescue
				login_v1
				$products_to_category = $client.call(:call){ message( session: $session,
																	  method: 'catalog_category.assignedProducts',
																	  categoryId: id
																	  )
													}.body[:call_response][:call_return][:item]
			end
		end
		
		def check_nil( products_to_category, id )
			unless $products_to_category == nil
				begin
					if ( products_to_category.class == Hash ) && products_to_category.include?( :item )
				    prod_id = products_to_category[:item][0][:value]
				    	if JoinTableCategoriesProduct.where(category_id: id, product_id: prod_id ).blank?
						    JoinTableCategoriesProduct.create(category_id: id, product_id: prod_id, new: true )
						    p "CAT ID: #{ id }, PROD ID: #{ prod_id } NEW!!!"
						end
					else
						products_to_category.map do |product|
						    prod_id = product[:item][0][:value]
						    if JoinTableCategoriesProduct.where(category_id: id, product_id: prod_id ).blank?
							    JoinTableCategoriesProduct.create(category_id: id, product_id: prod_id, new: true )
							    p "CAT ID: #{ id }, PROD ID: #{ prod_id } NEW!!!"
							end
						end
					end
				rescue
					p "check_nil in monitoring"
				end
			end
		end
		
		def login_v1
			$client  = Savon.client( wsdl: "http://tsw-admin.icommerce.se/api/?wsdl" )
			$request = $client.call( :login, message:{ magento_username: "developer",
																	key: "zCBt5lOPsdoaUYs1wu4jtVlFVG4FXIu6c7PGEAPJxohUqwnAde"
											    		}
									)
			$session = $request.body[:login_response][:login_return]
		end
		
		def login_v2
            $client  = Savon.client(wsdl: "http://tsw-admin.icommerce.se/api/v2_soap?wsdl" )
            $request = $client.call( :login, message:{ magento_username: "developer",
                                                       key:"zCBt5lOPsdoaUYs1wu4jtVlFVG4FXIu6c7PGEAPJxohUqwnAde" 
                                                        }
                                    )
            $session = $request.body[:login_response][:login_return]
        end
		
		def create_product_table
			$error_with_creating_product_table = []
			parsed_data = JoinTableCategoriesProduct.where(new: true).map{ |a| a.product_id }
			array_uniq_products_ids = parsed_data.uniq
			array_uniq_products_ids.map do |product_id|
    			begin
    				begin
    					prod = $client.call(:catalog_product_info, message: {session_id: $session, product_id: product_id , store_view: 4 }).body[:catalog_product_info_response][:info]
    				rescue
    					login_v2
    					prod = $client.call(:catalog_product_info, message: {session_id: $session, product_id: product_id , store_view: 4 }).body[:catalog_product_info_response][:info]
    				end
    				
    				# $all_products.map do |prod|
    					prod_in_table = Product.where(product_id: prod[:product_id])
    					if prod_in_table.blank?
    						if prod[:status] == "1"
    							begin
    								qty = []
    								$response = $client.call(:call){message(:session => $session, :method=> 'cataloginventory_stock_item.list', productId: prod[:product_id])}.body[:call_response][:call_return][:item][:item].map{|x| qty << x[:value] if (x[:key] == 'qty')}
    							rescue
    								login_v1
    								qty = []
    								$response = $client.call(:call){message(:session => $session, :method=> 'cataloginventory_stock_item.list', productId: prod[:product_id])}.body[:call_response][:call_return][:item][:item].map{|x| qty << x[:value] if (x[:key] == 'qty')}
    							end
    						else
    							qty = ['0']
    						end
    						if 	prod[:type] == "configurable"
    							p = Product.create(product_id: prod[:product_id], prod_type: prod[:type], sku: prod[:sku], name: prod[:name], ean: prod[:ean], description: prod[:description], price: prod[:price], special_price: prod[:special_price], special_from_date: prod[:special_from_date], special_to_date: prod[:special_to_date], url_key: prod[:url_key], image: prod[:image], color: prod[:color], status: prod[:status], weight: prod[:weight], set: prod[:set], size: prod[:size], qty: qty[0].to_i, new: true)
    							p "Product with ID: #{p.id}  added to the table"
    							begin	
    								simple_products = prod[:associated_products][:item]
    								unless simple_products.blank?
    									simple_products.map do |simple|
    										begin
    											if simple.include?(:product_id)
    												s_id        = simple[:product_id]
    												s_sku       = simple[:sku]
    												if simple[:options].include?(:item)
    													if (simple[:options][:item].count == 1) || (simple[:options][:item].include?(:"@xsi:type"))
    														s_size      = simple[:options][:item][:value]
    													else
    														size   = []
    														length = []
    														begin
    															simple[:options][:item].map do |s|
    																size << s[:value] if (s[:store_label] == "Size")
    																length << s[:value] if (s[:store_label] == "Length")
    															end
    														rescue
    															p 'ERROR WITH SIMPLE'
    														end
    													end
    													unless length.blank?
    														s_length = length[0]
    													else
    														s_length = nil
    													end
    													s_size   = size[0]   unless size.blank?
    													s_parent_id = prod[:product_id]
    													begin
    														qty = []
    														$response = $client.call(:call){message(:session => $session, :method=> 'cataloginventory_stock_item.list', productId: s_id)}.body[:call_response][:call_return][:item][:item].map{|x| qty << x[:value] if (x[:key] == 'qty')}
    													rescue
    														login_v1
    														qty = []
    														$response = $client.call(:call){message(:session => $session, :method=> 'cataloginventory_stock_item.list', productId: s_id)}.body[:call_response][:call_return][:item][:item].map{|x| qty << x[:value] if (x[:key] == 'qty')}
    													end
    													if 	ProductSimple.where(product_id: s_id, parent_id: s_parent_id, sku: s_sku, length: s_length, size: s_size, qty: qty[0].to_i).blank?
    														ProductSimple.create(product_id: s_id, parent_id: s_parent_id, sku: s_sku, length: s_length, size: s_size, qty: qty[0].to_i, new: true)
    														p 'add simple product'
    													end
    												else
    													p 'NOT INCLUDE SIMPLE'
    												end
    											end
    										rescue
    											p "deech"
    										end
    									end
    								end
    							rescue => e
    									p "without simple #{e} with prod #{prod[:product_id]}"
    							end
    				            p 'monitoring proccess done'
    						end
    					end
    			rescue
    				p 'product with error'
    			end
    		end
		end
		
		def create_products
            $error_prod = []
                    Product.includes(:images, :magento_categories).where("new = true and status = 1 and prod_type = 'configurable'").uniq.map do |product|
                    simples = []
                    product.product_simples.where(new: true).map{|a| simples << a if (a.qty > 0)}
                    unless simples.blank?
                            begin
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
                                            begin
                                                shop_product = ShopifyAPI::Product.new( @attributes={ 'title': title, 'body_html': body_html, 'handle': handle, options: [{name: "Size"}] } )
                                            rescue
                                                Auth.shopify
                                                shop_product = ShopifyAPI::Product.new( @attributes={ 'title': title, 'body_html': body_html, 'handle': handle, options: [{name: "Size"}] } )
                                            end
                                        else
                                            begin
                                                shop_product = ShopifyAPI::Product.new( @attributes={ 'title': title, 'body_html': body_html, 'handle': handle, "published_scope": "global", "published_at": nil, "published_status": "published", options: [{name: "Size"}] } )
                                            rescue
                                                Auth.shopify
                                                shop_product = ShopifyAPI::Product.new( @attributes={ 'title': title, 'body_html': body_html, 'handle': handle, "published_scope": "global", "published_at": nil, "published_status": "published", options: [{name: "Size"}] } )
                                            end
                                        end
                                        sleep 0.5
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
                            			rescue
                            			    login_v1
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
                                                        sleep 0.5
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
                                                        sleep 0.5
                                                        ip.save
                                                    end
                                                    simple.update_attributes(shopify_product_id: ip.variants.last.id)
                                                end
                                            end
                                            ip.variants.first.destroy if ip.variants.count > 2
                                        else
                                            if product.special_price == nil
                                                sleep 0.5
                                                ip.variants.first.update_attributes( 'sku': product.sku, 'price': product.price.to_i, 'barcode': product.ean, 'weight': product.weight, "inventory_policy": "continue", "inventory_management": "shopify", 'inventory_quantity': simples[0].qty, 'option1': simples[0].size )
                                            else
                                                sleep 0.5
                                                ip.variants.first.update_attributes( 'sku': product.sku, 'price': product.special_price.to_i, 'compare_at_price': product.price.to_i, 'barcode': product.ean, 'weight': product.weight, 'inventory_quantity': simples[0].qty, "inventory_policy": "continue", "inventory_management": "shopify", 'option1': simples[0].size )
                                            end
                                        end
                                        
                                        product.magento_categories.where(new: true).group(:category_id).distinct.map do |cat|
                                            unless cat.target_category_import.blank?
                                                category_targets = CategoryForMonitoring.where( magento_category_id: cat.category_id ).map(&:shopify_category_id)
                                                unless category_targets.blank?
                                                    category_targets.map do |shop_cat|
                                                        begin
                                                            if ShopifyAPI::Collect.find(:all, :params => {"collection_id": shop_cat, "product_id": id}).blank?
                                                                ShopifyAPI::Collect.create({"collection_id": shop_cat, "product_id": id})
                                                                print "Prod #{id} add to cat: #{shop_cat}"
                                                            end
                                                        rescue
                                                            Auth.shopify
                                                            if ShopifyAPI::Collect.find(:all, :params => {"collection_id": shop_cat, "product_id": id}).blank?
                                                                ShopifyAPI::Collect.create({"collection_id": shop_cat, "product_id": id})
                                                                print "Prod #{id} add to cat: #{shop_cat}"
                                                            end                                            
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                        #
                                        # delete if product haven`t images
                                        #
                                        # if ip.images.blank?
                                        #     title = ip.title
                                        #     begin
                                        #         prod = ShopifyAPI::Product.find(:all, :params => {'title': title }).last
                                        #         prod.destroy
                                        #         p 'product destroyed'
                                        #     rescue
                                        #         Auth.shopify
                                        #         prod = ShopifyAPI::Product.find(:all, :params => {'title': title })
                                        #         prod.destroy
                                        #         p 'product destroyed'
                                        #     end
                                        # end
                                        product.update_attributes(shopify_product_id: id)
                                    end
                                end
                            rescue => error
                                puts "Error with update product! Error: #{error}"
                            end
                    end
            end
        end
    end
    
    class Proccess
        def product
            begin
                Product_in_magento_shop.new.create_join_table_categories_products
                Product_in_magento_shop.new.create_product_table
                Product_in_magento_shop.new.create_products
                JoinTableCategoriesProduct.where(new: true).update_all(new: false)
                Product.where(new: true).update_all(new: false)
                ProductSimple.where(new: true).update_all(new: false)
                UserMailer.monitoring("success monitoring", 'Monitoring').deliver_now
            rescue => e
                UserMailer.monitoring(e, 'Monitoring').deliver_now
            end
        end
    end
end