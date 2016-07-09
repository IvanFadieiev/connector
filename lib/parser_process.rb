class ParserProcess
    def parse_categories(login)
        # @login = login
        Parser::Login.new.login( login )
        Parser::CategoryList.new.create_categories_table( login )
        login.update_column( :categories_parsed, true )
    end
    
    def parse_categories_attach(login)
        # Parser::ProductList.new.create_join_table_categories_products(login)
        # Parser::ProductList.new.create_product_table(login)
        Parser::Image.new.category_image(login)
        Parser::Image.new.product_image(login)
    end
end