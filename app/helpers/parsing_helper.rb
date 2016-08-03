module ParsingHelper
    
    def cat_tree(id, login)
        Import::CreateCategories.new.category_tree(id, login).map(&:category_id)
    end
end
