class ParserProcess
    def parse_categories(login)
        @login = login
        Parser::Login.new.login( "#{@login.store_url}/api/?wsdl", @login.username, @login.key, @login.store_id )
        Parser::CategoryList.new.create_categories_table( @login.store_id )
        @login.update_column( :categories_parsed, true )
    end
end