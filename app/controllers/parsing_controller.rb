class ParsingController < ApplicationController
    def category
        @login = Login.last
        Parser::Login.new.login( "#{@login.store_url}/api/?wsdl", @login.username, @login.key, @login.store_id )
        Thread.new do
            Parser::CategoryList.new.create_categories_table(@login.store_id)
            sleep 1
            redirect_to category_product_join_table_path
        end
        redirect_to category_parsing_path
    end
    
    def category_product_join_table
        
    end
end
