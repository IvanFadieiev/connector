require 'savon'
require 'active_support/core_ext/hash'
require 'active_support/core_ext/hash/conversions'
require 'byebug'
require 'csv'
require 'smarter_csv'
require 'open-uri'
# URL = 'http://tsw-admin.icommerce.se/api/?wsdl'

module Parser
	class Login
		def login( login )
			$client  = Savon.client( wsdl: login.store_url + '/api/?wsdl' )
			$request = $client.call( :login, message:{ magento_username: login.username,
																	key: login.key
											    		}
									)
			$session = $request.body[:login_response][:login_return]
		end
	end

	class CategoryList
		def categories(login)
			# Parser::Login.new.login( url, username, key, storeView )
			$response = $client.call( :call ){ message( session: $session, method: 'catalog_category.tree', storeView: login.store_id  ) }
		end

		def main_category(login)
			$items				 = categories(login).body[:call_response][:call_return][:item]
			$all_categories 	 = []
			$error 				 = []
			$error_key_params 	 = []
			$error_key_recursive = []
			hash_params($items)
		end

		def hash_params(items)
			begin
				arrr  = $client.call(:call){ message( session: $session,
																				 		  method: 'catalog_category.info',
																						  productId: items[0][:value]
																						 )
																		}.body[:call_response][:call_return][:item]
				$column_names = [ 'category_id', 'parent_id', 'name', 'description', 'is_active', 'level', 'image']
				Parser.new_array_with_object(arrr, $column_names)
			rescue
				$error << items
				puts "Category with ID = #{ items[0][:value] } add to the list!!!"
				puts "-------------------------------------------------------------------"
			end
			$all_categories << $hash
			p "Category with id #{ $hash.first[1] } added to the CATEGORY TABLE!!!"
			p "-------------------------------------------------------------------"
			begin
				if ( (items[6].class == Hash) && items[6][:value].keys.include?( :item ) ) || ( items[6].class == Array )
					recursive(items[6])
				end
			rescue
				$error_key_params << item
			end
		end

		def recursive( request )
			( request.class == Array )
			if request.class == Hash
				begin
					if request.keys.include?( :value )
						a = request[:value][:item]
					else
						a = request[:item]
					end
					if ( a.count == 7 ) && ( a[1][:key] == "parent_id" )
						hash_params( a )
					else
						a.map do |children|
							recursive( children )
						end
					end
				rescue
					$error_key_recursive << request
				end
			elsif request.class == Array
				if filter_conditions( request )
					request.map do |a|
						hash_params( a )
					end
				elsif ( request.count == 7 ) && ( request[1][:key] == "parent_id" )
					hash_params(request)
				else
					request.map do |children|
						recursive( children )
					end
				end
			end
		end

		def filter_conditions( request )
			( request.count == 7 ) &&
			( equest[0].class == Hash ) &&
			( request[1][:key] != "parent_id" ) &&
			( request[0].class == Array )
		end

		def create_categories_table(login)
			Parser::CategoryList.new.main_category(login)
			hashes = $all_categories
			# $column_names = [ 'category_id', 'parent_id', 'name', 'description', 'is_active', 'level', 'image' ]
			s = CSV.generate do |csv|
			  csv << $column_names
			  hashes.each do |x|
			    csv << x.values
			  end
			end
			File.write("public/#{login.id}/categories/categories.csv", s)
			p "categories is parsed"
		end
	end

	class ProductList
		def category_products( id )
			$products_to_category = $client.call(:call){ message( session: $session,
																  method: 'catalog_category.assignedProducts',
																  categoryId: id
																  )
												}.body[:call_response][:call_return][:item]
		end

		def check_nil( products_to_category, id, csv )
			unless $products_to_category == nil
				begin
					if ( products_to_category.class == Hash ) && products_to_category.include?( :item )
				    prod_id = products_to_category[:item][0][:value]
				    csv << [id, prod_id]
				    p "Add category ID: #{ id }, product ID: #{ prod_id }"
					else
						products_to_category.map do |product|
					    prod_id = product[:item][0][:value]
					    csv << [id, prod_id]
					    p "Add category ID: #{ id }, product ID: #{ prod_id }"
						end
					end
				rescue
					$array_cat << products_to_category
				end
			end
		end

		def create_join_table_categories_products(login)
			$array_cat = []
			# Parser::Login.new.login( 'http://tsw-admin.icommerce.se/api/?wsdl', "developer", "zCBt5lOPsdoaUYs1wu4jtVlFVG4FXIu6c7PGEAPJxohUqwnAde", 5 )
				s = CSV.generate do |csv|
					csv << [ "category_id", "products_id" ]
					$parsed_data = SmarterCSV.process( "public/#{login.id}/categories/categories.csv" ).map do |cat|
						id = cat[:category_id]
						p "Parsed category #{ id }"
						Parser::ProductList.new.category_products( id )
						Parser::ProductList.new.check_nil( $products_to_category, id, csv )
					end
				end
			File.write( "public/#{login.id}/categories_products/join_table_categories_products.csv", s )
		end

		def create_product_table(login)
			$error_with_creating_product_table = []
			parsed_data = SmarterCSV.process( "public/#{login.id}/categories_products/join_table_categories_products.csv" ).map{ |a| a[:products_id] }
			array_uniq_products_ids = parsed_data.uniq
			$custom_attr = [
											'modelsize',
											'size',
											'size_a',
											'size_b',
											'size_c',
											'size_d',
											'size_e',
											'size_f',
											'size_g',
											'size_h',
											'size_j'
										]
			$column_names = [
											'product_id',
											'type',
											'sku',
											'name',
											'ean',
											'description',
											'price',
											'special_price',
											'special_from_date',
											'special_to_date',
											'url_key',
											'image',
											'color',
											'status',
											'weight',
											'set'
											]
			$all_products = []
			$products_with_errors = []
			count = array_uniq_products_ids.count
			array_uniq_products_ids.map do |product_id|
				begin
					arrr = $client.call( :call ){ message( session: $session,
														  method: 'catalog_product.info',
														  productId: product_id
														  ) }.body[:call_response][:call_return][:item]
					Parser.new_array_with_object(arrr, $column_names)
					# object_attr_for_csv = []
					attr_hash = {}
					arrr_keys = arrr.map{|a| a[:key]}
					$custom_attr.map do |key|
						if arrr_keys.include?(key)
							arrr.map do |obj_attr_hash|
								if obj_attr_hash[:key] == key
									attr_hash.merge!('size'.to_sym => obj_attr_hash[:value])
								end
							end
						end
					end
					$hash.merge!(attr_hash)
					p "Add product with ID: #{arrr[0][:value]}"
					p "Left #{count+= -1} objects"
					p '------------------------------------------------------------------------'
					$all_products << $hash
				rescue
					$products_with_errors << $hash
				end
			end

			hashes = $all_products
			s = CSV.generate do |csv|
			  csv << ($column_names + ['size'])
			  hashes.each do |x|
			    csv << x.values
			  end
			end
			File.write("public/#{login.id}/products/products_table.csv", s)
		end

		def info_soap_product(product_id)
			$product = $client.call( :call ){ message( session: $session,
													  method: 'catalog_product.info',
													  productId: product_id
													  ) }.body[:call_response][:call_return][:item]
		end
	end

	class Image
		def category_image(login)
			parsed_data = SmarterCSV.process( "public/#{login.id}/categories_products/join_table_categories_products.csv" ).map{ |a| a[:category_id] }.uniq
			parsed_data.map do |category_id|
				arrr  = $client.call(:call){ message( session: $session,
													 		   method: 'catalog_category.info',
															   productId: category_id
															  )}.body[:call_response][:call_return][:item]
				image = []
				arrr.map{|a| image << a[:value] if ((a[:key] == "image" ) && (a[:value] != {:"@xsi:type"=>"xsd:string"}))}
				unless image[0].blank?
					open( "public/#{login.id}/image/category/#{image[0]}", 'wb') do |file|
						file << open("#{login.store_url}/media/catalog/category/#{image[0]}").read
						p "Image save for #{category_id} with image name: #{image[0]}!!!"
					end
				else
					p "Category with ID: #{category_id} havn`t image"
				end
			end
		end

		def product_image(login)
			$all_prod_imgs = []
			parsed_data = SmarterCSV.process( "public/#{login.id}/categories_products/join_table_categories_products.csv" ).map{ |a| a[:products_id] }.uniq
			parsed_data.map do |product_id|
				arrr = $client.call(:call){ message( session:   $session,
												     method:    'catalog_product_attribute_media.list',
											         productId: product_id
													 )
											}.body[:call_response][:call_return][:item]
				images  = []
				if arrr.class == Hash
					arrr[:item].map{ |a| images << a[:value] if (a[:key] == "url") } 
				else
					unless arrr == nil
						arrr.map{ |a| a[:item].map{ |b| images << b[:value] if ((b[:key] == "url") ) } }
					end
				end
				if images.any?
					images.map do |img_url|
						$error2 = []
						begin
						unless img_url.blank?
							# image_name = img_url.split("/").last
							# open( "public/#{login.id}/image/products/#{image_name}", 'wb') do |file|
							# 	file << open(img_url).read
								p "Image #{img_url} added in table for product with ID: #{product_id}!!!"
								obj_scv = {'product_id' => product_id, 'image_url' => img_url}
								$all_prod_imgs << obj_scv
							# end
						else
							p "Product with ID: #{product_id} havn`t image"
						end
						rescue
							$error2 << img_url
							p '-----------------------Error($error2)---------------------------'
							p '-----------------------Error($error2)---------------------------'
						end
					end
				end
			end
	
			hashes = $all_prod_imgs
			s = CSV.generate do |csv|
			  csv << ["product_id", "image_url"]
			  hashes.each do |x|
			    csv << x.values
			  end
			end
			File.write("public/#{login.id}/image/products/join_table_products_images_table.csv", s)
		end
	end

	def self.new_array_with_object(arrr, column_names)
		$hash = {}
		# object_attr_for_csv = []
		attr_hash = {}
		arrr_keys = arrr.map{|a| a[:key]}
		column_names.map do |key|
			if arrr_keys.include?(key)
				arrr.map do |obj_attr_hash|
					if obj_attr_hash[:key] == key
						attr_hash.merge!(key.to_sym => obj_attr_hash[:value])
					end
				end
			else
				attr_hash.merge!(key.to_sym => nil)
			end
		end
		$hash.merge!(attr_hash)
	end
end




# p '-------------------------------------------------------------------------------------------'
# p '-------------------------------------------------------------------------------------------'
# p '-------------------------------------------------------------------------------------------'
# p "Do you want to create CATEGORIES listing? yes/no"
# answer = gets.chomp
# case answer
# 	when "yes", "y"
#  		p '---------------------------------------------------------------------------------------'
# 		start = Time.now
# 		p 'Start of the parsing categories'
# 		Parser::CategoryList.new.create_categories_table( url, username, key, storeView )
# 		stop = Time.now
# 		time  =  stop - start
# 		min = ( time/60 ).to_i
# 		sec = ( time - min*60 ).to_i
# 		p "Operation took: #{ min } min #{ sec } sec!"
# 		p '---------------------------------------------------------------------------------------'
# 	else
# 		"Ok, we go ahead!"
# 	end


# p '-------------------------------------------------------------------------------------------'
# p '-------------------------------------------------------------------------------------------'
# p '-------------------------------------------------------------------------------------------'
# p "Do you want to create JOIN TABLE CATEGORY_PRODUCT listing? yes/no"
# answer = gets.chomp
# case answer
# 	when "yes", "y"
# 		start = Time.now
# 		Parser::ProductList.new.create_join_table_categories_products
# 		stop = Time.new
# 		time  =  stop - start
# 		min = ( time/60 ).to_i
# 		sec = ( time - min*60 ).to_i
# 		p "Operation took: #{ min } min #{ sec } sec!"
# 	else
# 		"Ok, we go ahead!"
# 	end



# p '-------------------------------------------------------------------------------------------'
# p '-------------------------------------------------------------------------------------------'
# p '-------------------------------------------------------------------------------------------'
# p "Do you want to create products listing? yes/no"
# answer = gets.chomp
# case answer
# 	when "yes", "y"
# 		start = Time.now
# 		Parser::ProductList.new.create_product_table
# 		stop = Time.new
# 		time  =  stop - start
# 		min = ( time/60 ).to_i
# 		sec = ( time - min*60 ).to_i
# 		p "Operation took: #{ min } min #{ sec } sec!"
# 	else
# 		"Ok, we go ahead!"
# 	end


# p '-------------------------------------------------------------------------------------------'
# p '-------------------------------------------------------------------------------------------'
# p '-------------------------------------------------------------------------------------------'
# p "Do you want to create IMAGES FOR CATEGORIES? yes/no"
# answer = gets.chomp
# case answer
# 	when "yes", "y"
#  		p '---------------------------------------------------------------------------------------'
# 		start = Time.now
#     Parser::Image.new.category_image
# 		stop = Time.now
# 		time  =  stop - start
# 		min = ( time/60 ).to_i
# 		sec = ( time - min*60 ).to_i
# 		p "Operation took: #{ min } min #{ sec } sec!"
# 		p '---------------------------------------------------------------------------------------'
# 	else
# 		"Ok, we go ahead!"
# 	end


# p '-------------------------------------------------------------------------------------------'
# p '-------------------------------------------------------------------------------------------'
# p '-------------------------------------------------------------------------------------------'
# p "Do you want to create IMAGES FOR PRODUCTS? yes/no"
# answer = gets.chomp
# case answer
# 	when "yes", "y"
#  		p '---------------------------------------------------------------------------------------'
# 		start = Time.now
#     Parser::Image.new.product_image
# 		stop = Time.now
# 		time  =  stop - start
# 		min = ( time/60 ).to_i
# 		sec = ( time - min*60 ).to_i
# 		p "Operation took: #{ min } min #{ sec } sec!"
# 		p '---------------------------------------------------------------------------------------'
# 	else
# 		"Ok, we go ahead!"
# 	end

# dirs = []
# dirs << File.dirname("#{Rails.root}/public/categories/categories.log")
# dirs << File.dirname("#{Rails.root}/public/categories_products/categories_products.log")
# dirs << File.dirname("#{Rails.root}/public/image/image.log")
# dirs << File.dirname("#{Rails.root}/public/image/category/image.log")
# dirs << File.dirname("#{Rails.root}/public/image/products/image.log")
# dirs << File.dirname("#{Rails.root}/public/products/products.log")
# dirs.map do |dir|
#   FileUtils.mkdir_p(dir) unless File.directory?(dir)
# end