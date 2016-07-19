class ParserProcess
    def parse_categories(login)
        # @login = login
        # login = Login.find(451)
        Parser::Login.new.login( login )
        Parser::CategoryList.new.create_categories_table( login )
        login.update_column( :categories_parsed, true )
    end
    
    def parse_categories_attach_and_create_objects(login)
        # login = Login.find(1)
        Parser::ProductList.new.create_join_table_categories_products(login)
        Parser::ProductList.new.create_product_table(login)
        Parser::Login.new.login( login )
        Parser::Image.new.product_image(login)
        Import::CreateCategories.new.create(login)
        # sleep 10
        Import::CreateProducts.new.create_products_to_shop(login)
        if login.email
            UserMailer.letter(login).deliver_now
        end
    end
end