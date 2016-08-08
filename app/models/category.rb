class Category < ActiveRecord::Base
    belongs_to :collection
    has_many   :childrens,       class_name: 'Category', primary_key: :category_id, foreign_key: :parent_id
    belongs_to :parent_category, class_name: 'Category', primary_key: :category_id
    
    before_create :attr_filtering
    
    def attr_filtering
         keys = []
         self.attributes.select{ |k,v| keys << k if (v.class == String)}
         keys.map{ |a| self[a.to_sym].gsub!(/[@{}$&]/, '') }
    end
end
