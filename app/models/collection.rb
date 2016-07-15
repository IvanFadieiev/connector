class Collection < ActiveRecord::Base
    has_one :category, class_name: 'Category', primary_key: :magento_category_id, foreign_key: :category_id
end
