class Product < ActiveRecord::Base
    self.primary_key = 'product_id'
    has_many :images,             class_name: 'ProductImage', primary_key: 'product_id', foreign_key: 'product_id'
    has_many :magento_categories, class_name: 'JoinTableCategoriesProduct', foreign_key: 'product_id'
    has_many :product_simples,    class_name: "ProductSimple", foreign_key: 'parent_id'
    extend ShopSession
    
    before_create :attr_filtering
    
    def attr_filtering
         keys = []
         self.attributes.select{ |k,v| keys << k if (v.class == String)}
         keys.map{ |a| self[a.to_sym].gsub!(/[@{}$&]/, '') }
    end
end
