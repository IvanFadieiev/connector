class ParserProcess
    def parse_categories
        @login = Login.last
        Parser::Login.new.login( "#{@login.store_url}/api/?wsdl", @login.username, @login.key, @login.store_id )
        Parser::CategoryList.new.create_categories_table(@login.store_id)
    end
end