class ParserProcess
    
    def parse_categories(login)
        # @login = login
        # login = Login.find(451)
        Parser::Login.new.login( login )
        Parser::CategoryList.new.create_categories_table( login )
        login.update_column( :categories_parsed, true )
    end
    
    def parse_categories_attach_and_create_objects(login)
        login.update_column( :counter, 0 )
        login.update_column( :magento_product_count, 0 )
        # login = Login.find(Session.find_by(session_id: session.id).data['warden.user.vendor.key'][0][0])
        login = login
        Parser::ProductList.new.create_join_table_categories_products(login)
        Parser::ProductList.new.create_product_table(login)
        Parser::Login.new.login( login )
        # Parser::Image.new.product_image(login)
        Import::CreateCategories.new.create(login)
        # sleep 10
        Import::CreateProducts.new.create_products_to_shop(login)
        email = Vendor.find(login.vendor_id).email
        unless email.blank?
            UserMailer.letter(email).deliver_now
        end
    end
end