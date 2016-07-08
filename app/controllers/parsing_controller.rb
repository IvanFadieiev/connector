class ParsingController < ApplicationController
    def category
        ParserProcess.new.delay.parse_categories
        redirect_to parsing_categories_start_path
    end
    
    def parsing_categories_start
        
    end
    
    def category_product_join_table
        
    end
end
