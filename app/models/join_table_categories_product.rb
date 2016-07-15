class JoinTableCategoriesProduct < ActiveRecord::Base
    # self.primary_key = 'product_id'
    belongs_to :product
    has_one :target_category_import, class_name: 'TargetCategoryImport', primary_key: 'category_id', foreign_key: 'magento_category_id'
end
