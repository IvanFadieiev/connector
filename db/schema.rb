# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160719195944) do

  create_table "categories", force: :cascade do |t|
    t.integer  "category_id"
    t.integer  "parent_id"
    t.string   "name"
    t.text     "description"
    t.string   "is_active"
    t.integer  "level"
    t.string   "image"
    t.integer  "login_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.boolean  "chosen"
  end

  add_index "categories", ["category_id"], name: "index_categories_on_category_id"
  add_index "categories", ["parent_id"], name: "index_categories_on_parent_id"

  create_table "collections", force: :cascade do |t|
    t.integer  "shopify_category_id"
    t.integer  "magento_category_id"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.integer  "login_id"
  end

  add_index "collections", ["magento_category_id"], name: "index_collections_on_magento_category_id"
  add_index "collections", ["shopify_category_id"], name: "index_collections_on_shopify_category_id"

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   default: 0, null: false
    t.integer  "attempts",   default: 0, null: false
    t.text     "handler",                null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority"

  create_table "join_table_categories_products", force: :cascade do |t|
    t.integer  "category_id"
    t.integer  "product_id"
    t.integer  "login_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "join_table_categories_products", ["category_id"], name: "index_join_table_categories_products_on_category_id"
  add_index "join_table_categories_products", ["product_id"], name: "index_join_table_categories_products_on_product_id"

  create_table "logins", force: :cascade do |t|
    t.string   "username"
    t.string   "key"
    t.integer  "store_id"
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.string   "store_url"
    t.boolean  "categories_parsed", default: false
    t.string   "target_url"
    t.string   "email"
  end

  create_table "product_images", force: :cascade do |t|
    t.integer  "product_id"
    t.string   "img_url"
    t.integer  "login_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "product_images", ["product_id"], name: "index_product_images_on_product_id"

  create_table "products", force: :cascade do |t|
    t.integer  "product_id"
    t.string   "prod_type"
    t.string   "sku"
    t.string   "name"
    t.string   "ean"
    t.text     "description"
    t.string   "price"
    t.string   "special_price"
    t.string   "special_from_date"
    t.string   "special_to_date"
    t.string   "url_key"
    t.string   "image"
    t.string   "color"
    t.string   "status"
    t.string   "weight"
    t.string   "set"
    t.string   "size"
    t.integer  "login_id"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.integer  "shopify_product_id", limit: 8
  end

  add_index "products", ["product_id"], name: "index_products_on_product_id"

  create_table "shops", force: :cascade do |t|
    t.string   "shopify_domain", null: false
    t.string   "shopify_token",  null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "shops", ["shopify_domain"], name: "index_shops_on_shopify_domain", unique: true

  create_table "target_category_imports", force: :cascade do |t|
    t.integer  "magento_category_id"
    t.integer  "shopify_category_id"
    t.integer  "login_id"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
  end

  add_index "target_category_imports", ["magento_category_id"], name: "index_target_category_imports_on_magento_category_id"
  add_index "target_category_imports", ["shopify_category_id"], name: "index_target_category_imports_on_shopify_category_id"

end
