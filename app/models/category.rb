class Category < ActiveRecord::Base
    belongs_to :collection
    has_many   :childrens,       class_name: 'Category', primary_key: :category_id, foreign_key: :parent_id
    belongs_to :parent_category, class_name: 'Category', primary_key: :category_id
end
