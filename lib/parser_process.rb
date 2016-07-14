class ParserProcess
    def parse_categories(login)
        # @login = login
        Parser::Login.new.login( login )
        Parser::CategoryList.new.create_categories_table( login )
        login.update_column( :categories_parsed, true )
    end
    
    def parse_categories_attach_and_create_objects(login)
        # Parser::ProductList.new.create_join_table_categories_products(login)
        # Parser::ProductList.new.create_product_table(login)
        # # без надобности
        # # Parser::Image.new.category_image(login)
        login = Login.find(424)
        Parser::Login.new.login( login )
        Parser::Image.new.product_image(login)
        # Import::CreateCategories.new.create(login)
        # Import::CreateProducts.new.create_products_to_shop(login)
    end
end