class ParserProcess
    def parse_categories(login)
        @login = login
        Parser::Login.new.login( login )
        Parser::CategoryList.new.create_categories_table( login )
        @login.update_column( :categories_parsed, true )
    end
end