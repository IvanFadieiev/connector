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
			begin
				# $response = $client.call( :call ){ message( session: $session, method: 'catalog_category.tree', storeView: login.store_id  ) }
				$response = $client.call(:catalog_category_tree, message: {:sessionId => $session, parent_id: 2, store_view: login.store_id }).body[:catalog_category_tree_response][:tree]
			rescue
				# Parser::Login.new.login(login)
				# $response = $client.call( :call ){ message( session: $session, method: 'catalog_category.tree', storeView: login.store_id  ) }
				AuthSavon.connect( login )
				$response = $client.call(:catalog_category_tree, message: {:sessionId => $session, parent_id: 2, store_view: login.store_id }).body[:catalog_category_tree_response][:tree]
			end
		end

		def main_category(login)
			# $items				 = categories(login).body[:call_response][:call_return][:item]
			# $error 				 = []
			# $error_key_params 	 = []
			# $error_key_recursive = []
			# hash_params($items, login)
			$items				 =  categories(login)
			$error 				 = []
			$error_key_params 	 = []
			$error_key_recursive = []
			hash_params($items, login)
		end

		def hash_params(items, login)
			begin
				# arrr  = $client.call(:call){ message( session: $session,
				# 																 		  method: 'catalog_category.info',
				# 																		  productId: items[0][:value]
				# 																		 )
				# 														}.body[:call_response][:call_return][:item]
				
				$column_names = [ 'category_id', 'parent_id', 'name', 'description', 'is_active', 'level', 'image']
				# Parser.new_array_with_object(arrr, $column_names, login)
				
				Parser::CategoryList.new.create_magento_category(items, login)
				
				
				
				
				# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
				# unless Category.find_by(name: attr_hash[:name], login_id: login.id)
				# 	cat_to_p = Category.create(category_id: attr_hash[:category_id], parent_id: attr_hash[:parent_id], name: attr_hash[:name], description: attr_hash[:description], is_active: attr_hash[:is_active].to_i, level: attr_hash[:level].to_i, image: attr_hash[:image], login_id: login.id)
				# 	p "Category with id #{ cat_to_p.category_id } added to the CATEGORY TABLE!!!"
				# end
				# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
				
				
				
				
			rescue => e
				p "#{e}"
			end

			# begin
			# 	if ( (items[6].class == Hash) && items[6][:value].keys.include?( :item ) ) || ( items[6].class == Array )
			# 		recursive(items[6], login)
			# 	end
			# rescue
			# 	$error_key_params << item
			# end
		end
		
		def create_magento_category(items, login)
			begin	
				if items.class == Hash	
					if items.keys.include?(:category_id)
						create_categy(items, login)
						if items[:children].keys.include?(:item)
							if 	(items[:children][:item].class == Hash) && (items[:children][:item].keys.include?(:category_id))
								create_magento_category(items[:children][:item], login)
							else
								items[:children][:item].map do |category|
									# byebug
									byebug if category.count == 2
									create_magento_category( category, login )
								end
							end
						end
					elsif items.keys.include?(:item)
						items[:item].map do |cat|
							create_magento_category(cat, login)
						end
					end
				elsif items.class == Array
					byebug
					items.map do |item|
						unless item == :item
							create_magento_category(items, login)
						end
					end
				end
			rescue => e
				p e
			end
		end
		
		def create_categy(items, login)
			unless Category.find_by(name: items[:name], login_id: login.id)
				cat_to_p = Category.create(category_id: items[:category_id], parent_id: items[:parent_id], name: items[:name], description: items[:description], is_active: items[:is_active].to_i, level: items[:level].to_i, image: items[:image], login_id: login.id)
				unless items[:children].class == Hash
					cat_to_p.update_column(:children, items[:children])
				end
	 			p "Category with id #{ cat_to_p.category_id } added to the CATEGORY TABLE!!!"
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
				$products_to_category = $client.call(:call){ message( session: $session,
																	  method: 'catalog_category.assignedProducts',
																	  categoryId: id
																	  )
													}.body[:call_response][:call_return][:item]
			end
		end

		def check_nil( products_to_category, id, login )
			unless $products_to_category == nil
				begin
					if ( products_to_category.class == Hash ) && products_to_category.include?( :item )
				    prod_id = products_to_category[:item][0][:value]
				    	if JoinTableCategoriesProduct.where(category_id: id, product_id: prod_id, login_id: login.id ).blank?
						    JoinTableCategoriesProduct.create(category_id: id, product_id: prod_id, login_id: login.id )
						    p "CAT ID: #{ id }, PROD ID: #{ prod_id } login #{login.id}"
						end
					else
						products_to_category.map do |product|
						    prod_id = product[:item][0][:value]
						    if JoinTableCategoriesProduct.where(category_id: id, product_id: prod_id, login_id: login.id).blank?
							    JoinTableCategoriesProduct.create(category_id: id, product_id: prod_id, login_id: login.id)
							    p "CAT ID: #{ id }, PROD ID: #{ prod_id } login #{login.id}"
							end
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
			
			# array_category = Parser::ProductList.new.array_of_categories_tree(login).flatten.map |c|
			# 	find_cat = Category.find_by(category_id: c, login_id: login.id)
			# 	unless find_cat.blank?
			# 		id = find_cat.category_id
			# 		array_category.delete_if{|m| m == id}
			# 	end
			# end
			
			# подставить array_category вместо Parser::ProductList.new.array_of_categories_tree(login).flatten 
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
			# $custom_attr = [
			# 								'modelsize',
			# 								'size',
			# 								'size_a',
			# 								'size_b',
			# 								'size_c',
			# 								'size_d',
			# 								'size_e',
			# 								'size_f',
			# 								'size_g',
			# 								'size_h',
			# 								'size_j'
			# 							]
			# $column_names = [
			# 								'product_id',
			# 								'type',
			# 								'sku',
			# 								'name',
			# 								'ean',
			# 								'description',
			# 								'price',
			# 								'special_price',
			# 								'special_from_date',
			# 								'special_to_date',
			# 								'url_key',
			# 								'image',
			# 								'color',
			# 								'status',
			# 								'weight',
			# 								'set'
			# 								]
			# $all_products = []
			# $products_with_errors = []
			count = array_uniq_products_ids.count
			array_uniq_products_ids.map do |product_id|
				begin
					begin
						# arrr = $client.call( :call ){ message( session: $session,
						# 										  method: 'catalog_product.info',
						# 										  productId: product_id
						# 										  ) }.body[:call_response][:call_return][:item]			
						prod = $client.call(:catalog_product_info, message: {session_id: $session, product_id: product_id , store_view: login.store_id }).body[:catalog_product_info_response][:info]
					rescue
						# Parser::Login.new.login(login)
						# arrr = $client.call( :call ){ message( session: $session,
						# 											  method: 'catalog_product.info',
						# 											  productId: product_id
						# 											  ) }.body[:call_response][:call_return][:item]
						AuthSavon.connect( login )
						prod = $client.call(:catalog_product_info, message: {session_id: $session, product_id: product_id , store_view: login.store_id }).body[:catalog_product_info_response][:info]
					end
					
					# $all_products.map do |prod|
						prod_in_table = Product.where(login_id: login.id, product_id: prod[:product_id])
						if prod_in_table.blank?
							magento_product_count = login.magento_product_count
							login.update_column( :magento_product_count, magento_product_count + 1 )
							if prod[:status] == "1"
								begin
									qty = []
									$response = $client.call(:call){message(:session => $session, :method=> 'cataloginventory_stock_item.list', productId: prod[:product_id])}.body[:call_response][:call_return][:item][:item].map{|x| qty << x[:value] if (x[:key] == 'qty')}
								rescue
									Parser::Login.new.login(login)
									qty = []
									$response = $client.call(:call){message(:session => $session, :method=> 'cataloginventory_stock_item.list', productId: '21268')}.body[:call_response][:call_return][:item][:item].map{|x| qty << x[:value] if (x[:key] == 'qty')}
								end
							else
								qty = ['0']
							end
							p = Product.create(product_id: prod[:product_id], prod_type: prod[:type], sku: prod[:sku], name: prod[:name], ean: prod[:ean], description: prod[:description], price: prod[:price], special_price: prod[:special_price], special_from_date: prod[:special_from_date], special_to_date: prod[:special_to_date], url_key: prod[:url_key], image: prod[:image], color: prod[:color], status: prod[:status], weight: prod[:weight], set: prod[:set], size: prod[:size], qty: qty[0].to_i, login_id: login.id)
							p "Product with ID: #{p.id}  added to the table"
							p "Left #{count+= -1} prod"
						end
					# end
					# Parser.new_array_with_object(arrr, $column_names, login)
					# attr_hash = {}
					# arrr_keys = arrr.map{|a| a[:key]}
					# $custom_attr.map do |key|
					# 	if arrr_keys.include?(key)
					# 		arrr.map do |obj_attr_hash|
					# 			if obj_attr_hash[:key] == key
					# 				attr_hash.merge!('size'.to_sym => obj_attr_hash[:value])
					# 			end
					# 		end
					# 	end
					# end
					# $hash.merge!(attr_hash)
					# # p "Add product with ID: #{arrr[0][:value]}"
					# p "Left #{count+= -1} prod"
					# # p '------------------------------------------------------------------------'
					# $all_products << $hash
				rescue
					# $products_with_errors << $hash
					p 'product with error'
				end
			end
			
			# $all_products.map do |prod|
			# 	prod_in_table = Product.where(login_id: login.id, product_id: prod[:product_id])
			# 	if prod_in_table.blank?
			# 		magento_product_count = login.magento_product_count
			# 		login.update_column( :magento_product_count, magento_product_count + 1 )
			# 		p = Product.create(product_id: prod[:product_id], prod_type: prod[:type], sku: prod[:sku], name: prod[:name], ean: prod[:ean], description: prod[:description], price: prod[:price], special_price: prod[:special_price], special_from_date: prod[:special_from_date], special_to_date: prod[:special_to_date], url_key: prod[:url_key], image: prod[:image], color: prod[:color], status: prod[:status], weight: prod[:weight], set: prod[:set], size: prod[:size], login_id: login.id)
			# 		p "Product with ID: #{p.id}  added to the table"
			# 	# else
			# 	# 	prod_in_table.map do |p|
			# 	# 		p.update_column(:login_id, login.id)
			# 	# 		p 'product login_id updated'
			# 	# 	end
			# 	end
			# end
			# $all_products = []
		end

		def info_soap_product(product_id)
			begin
				arrr = $client.call( :call ){ message( session: $session,
														  method: 'catalog_product.info',
														  productId: product_id
														  ) }.body[:call_response][:call_return][:item]			
			rescue
				Parser::Login.new.login(login)
				arrr = $client.call( :call ){ message( session: $session,
															  method: 'catalog_product.info',
															  productId: product_id
															  ) }.body[:call_response][:call_return][:item]
			end
		end
	end

	class Image
		def category_image(login)
			parsed_data = SmarterCSV.process( "public/#{login.id}/categories_products/join_table_categories_products.csv" ).map{ |a| a[:category_id] }.uniq
			parsed_data.map do |category_id|
				begin
					arrr = $client.call(:call){ message( session: $session,
													 		   method: 'catalog_category.info',
															   productId: category_id
															  )}.body[:call_response][:call_return][:item]			
				rescue
					Parser::Login.new.login(login)
					arrr = $client.call(:call){ message( session: $session,
													 		   method: 'catalog_category.info',
															   productId: category_id
															  )}.body[:call_response][:call_return][:item]
				end
				
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
				begin
					arrr = $client.call(:call){ message( session:   $session,
												     method:    'catalog_product_attribute_media.list',
											         productId: product_id
													 )
											}.body[:call_response][:call_return][:item]			
				rescue
					Parser::Login.new.login(login)
					arrr = $client.call(:call){ message( session:   $session,
												     method:    'catalog_product_attribute_media.list',
											         productId: product_id
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
			unless Category.find_by(name: attr_hash[:name], login_id: login.id)
				cat_to_p = Category.create(category_id: attr_hash[:category_id], parent_id: attr_hash[:parent_id], name: attr_hash[:name], description: attr_hash[:description], is_active: attr_hash[:is_active].to_i, level: attr_hash[:level].to_i, image: attr_hash[:image], login_id: login.id)
				p "Category with id #{ cat_to_p.category_id } added to the CATEGORY TABLE!!!"
			end
		end
		$hash.merge!(attr_hash)
	end
end
