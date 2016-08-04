class ProductSimple < ActiveRecord::Base
    self.primary_key = 'product_id'
    belongs_to :product
end
