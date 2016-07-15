class Product < ActiveRecord::Base
    self.primary_key = 'product_id'
    has_many :images, class_name: 'ProductImage', foreign_key: 'product_id'
    has_many :magento_categories, class_name: 'JoinTableCategoriesProduct', foreign_key: 'product_id'
end
