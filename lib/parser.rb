require 'savon'
require 'active_support/core_ext/hash'
require 'active_support/core_ext/hash/conversions'
require 'byebug'
require 'csv'
require 'smarter_csv'
require 'open-uri'
require 'import'
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
			# $response = $client.call( :call ){ message( session: $session, method: 'catalog_category.tree', storeView: login.store_id  ) }
			$response = $client.call( :call ){ message( session: $session, method: 'catalog_category.tree', storeView: login.store_id  ) }
		end

		def main_category(login)
			$items				 = categories(login).body[:call_response][:call_return][:item]
			$error 				 = []
			$error_key_params 	 = []
			$error_key_recursive = []
			hash_params($items, login)
		end

		def hash_params(items, login)
			begin
				arrr  = $client.call(:call){ message( session: $session,
																				 		  method: 'catalog_category.info',
																						  productId: items[0][:value]
																						 )
																		}.body[:call_response][:call_return][:item]
				$column_names = [ 'category_id', 'parent_id', 'name', 'description', 'is_active', 'level', 'image']
				Parser.new_array_with_object(arrr, $column_names, login)
			rescue
				$error << items
				p $error
			end

			begin
				if ( (items[6].class == Hash) && items[6][:value].keys.include?( :item ) ) || ( items[6].class == Array )
					recursive(items[6], login)
				end
			rescue
				$error_key_params << item
			end
		end

		def recursive( request, login )
			( request.class == Array )
			if request.class == Hash
				begin
					if request.keys.include?( :value )
						a = request[:value][:item]
					else
						a = request[:item]
					end
					if ( a.count == 7 ) && ( a[1][:key] == "parent_id" )
						hash_params( a , login)
					else
						a.map do |children|
							recursive( children, login )
						end
					end
				rescue
					$error_key_recursive << request
				end
			elsif request.class == Array
				if filter_conditions( request )
					request.map do |a|
						hash_params( a, login )
					end
				elsif ( request.count == 7 ) && ( request[1][:key] == "parent_id" )
					hash_params(request, login)
				else
					request.map do |children|
						recursive( children, login )
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
			p "categories is parsed"
		end
	end

	class ProductList
		def category_products( id, login )
			begin
				$products_to_category = $client.call(:call){ message( session: $session,
																	  method: 'catalog_category.assignedProducts',
																	  categoryId: id
																	  )
													}.body[:call_response][:call_return][:item]
			rescue
				Parser::Login.new.login(login)
			end
		end

		def check_nil( products_to_category, id, login )
			unless $products_to_category == nil
				begin
					if ( products_to_category.class == Hash ) && products_to_category.include?( :item )
				    prod_id = products_to_category[:item][0][:value]
				    JoinTableCategoriesProduct.create(category_id: id, product_id: prod_id, login_id: login.id )
				    p "CAT ID: #{ id }, PROD ID: #{ prod_id } login #{login.id}"
					else
						products_to_category.map do |product|
					    prod_id = product[:item][0][:value]
					    JoinTableCategoriesProduct.create(category_id: id, product_id: prod_id, login_id: login.id)
					    p "CAT ID: #{ id }, PROD ID: #{ prod_id } login #{login.id}"
						end
					end
				rescue
					# $array_cat << products_to_category
				end
			end
		end

		def create_join_table_categories_products(login)
			# $array_cat = []
			# # $parsed_data = Category.where(login_id: login.id).map do |cat|
			# $parsed_data = Collection.where( login_id: login.id).each do |cat|
			# 	id = cat.magento_category_id
			# # $parsed_data = Category.where(login_id: login.id, chosen: true).map do |cat|
			# 	# id = cat.category_id
			# 	p "Parsed category #{ id }"
			# 	Parser::ProductList.new.category_products( id )
			# 	Parser::ProductList.new.check_nil( $products_to_category, id, login )
			# end
			$array_cat = []
			Parser::ProductList.new.array_of_categories_tree(login).flatten.each do |cat_id|
				p "Parsed category #{ cat_id }"
				Parser::ProductList.new.category_products( cat_id, login )
				Parser::ProductList.new.check_nil( $products_to_category, cat_id, login )
			end
		end
		
		def array_of_categories_tree(login)
			mag_ids = Collection.where(login_id: login.id).map(&:magento_category_id)
			@all_trees = []
			mag_ids.map do |mag_id|
				@all_trees << Import::CreateCategories.new.category_tree(mag_id, login).map(&:category_id)
			end
			@all_trees.sort!
			
			s = @all_trees.size - 1
			0.upto(s) do |n|
				0.upto(s) do |i|
					unless @all_trees[n] == @all_trees[i]
						if @all_trees[n].include?(@all_trees[i][0])
							@all_trees[i].map do |c|
								@all_trees[n].reject!{ |b| b == c }
							end
						end
					end
				end
			end
			skiped = Collection.where( shopify_category_id: -1, login_id: login.id ).map( &:magento_category_id )
			unless skiped.blank?
				skiped.map do |rej|
					@all_trees.map do |e|
						unless rej == e
							if e.include?(rej)
								e.reject!{ |y| y == rej }
							end
						end
					end
				end
			end
			@all_trees.delete_if{|j| j.blank? }
		end
		
		def create_product_table(login)
			$error_with_creating_product_table = []
			parsed_data = JoinTableCategoriesProduct.where(login_id: login.id).map{ |a| a.product_id }
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
					Parser.new_array_with_object(arrr, $column_names, login)
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
					# p "Add product with ID: #{arrr[0][:value]}"
					p "Left #{count+= -1} prod"
					# p '------------------------------------------------------------------------'
					$all_products << $hash
				rescue
					$products_with_errors << $hash
				end
			end
			
			$all_products.map do |prod|
				p = Product.create(product_id: prod[:product_id], prod_type: prod[:type], sku: prod[:sku], name: prod[:name], ean: prod[:ean], description: prod[:description], price: prod[:price], special_price: prod[:special_price], special_from_date: prod[:special_from_date], special_to_date: prod[:special_to_date], url_key: prod[:url_key], image: prod[:image], color: prod[:color], status: prod[:status], weight: prod[:weight], set: prod[:set], size: prod[:size], login_id: login.id)
				p "Product with ID: #{p.id}  added to the table"
			end
			$all_products = []
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
			parsed_data = JoinTableCategoriesProduct.where(login_id: login.id).map{ |a| a.product_id }.uniq
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
								i = ProductImage.create(product_id: product_id, img_url: img_url, login_id: login.id )
								p "Image for Product add to table #{i.img_url}"
							rescue
							 p 'don`t valid uri'	
							end
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
		end
	end

	def self.new_array_with_object(arrr, column_names, login)
		$hash = {}
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
		if attr_hash.keys.include?(:category_id) && attr_hash.keys.include?(:parent_id)
			cat_to_p = Category.create(category_id: attr_hash[:category_id], parent_id: attr_hash[:parent_id], name: attr_hash[:name], description: attr_hash[:description], is_active: attr_hash[:is_active].to_i, level: attr_hash[:level].to_i, image: attr_hash[:image], login_id: login.id)
			p "Category with id #{ cat_to_p.category_id } added to the CATEGORY TABLE!!!"
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