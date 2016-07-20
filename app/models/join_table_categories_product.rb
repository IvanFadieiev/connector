class JoinTableCategoriesProduct < ActiveRecord::Base
    belongs_to :product
    has_many :target_category_import, class_name: 'TargetCategoryImport', primary_key: 'category_id', foreign_key: 'magento_category_id'
end
