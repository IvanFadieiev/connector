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

ActiveRecord::Schema.define(version: 20160729092151) do

  create_table "categories", force: :cascade do |t|
    t.integer  "category_id", limit: 4
    t.integer  "parent_id",   limit: 4
    t.string   "name",        limit: 255
    t.text     "description", limit: 65535
    t.string   "is_active",   limit: 255
    t.integer  "level",       limit: 4
    t.string   "image",       limit: 255
    t.integer  "login_id",    limit: 4
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.boolean  "chosen"
  end

  add_index "categories", ["category_id"], name: "index_categories_on_category_id", using: :btree
  add_index "categories", ["parent_id"], name: "index_categories_on_parent_id", using: :btree

  create_table "collections", force: :cascade do |t|
    t.integer  "shopify_category_id", limit: 4
    t.integer  "magento_category_id", limit: 4
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.integer  "login_id",            limit: 4
  end

  add_index "collections", ["magento_category_id"], name: "index_collections_on_magento_category_id", using: :btree
  add_index "collections", ["shopify_category_id"], name: "index_collections_on_shopify_category_id", using: :btree

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   limit: 4,     default: 0, null: false
    t.integer  "attempts",   limit: 4,     default: 0, null: false
    t.text     "handler",    limit: 65535,             null: false
    t.text     "last_error", limit: 65535
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by",  limit: 255
    t.string   "queue",      limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "join_table_categories_products", force: :cascade do |t|
    t.integer  "category_id", limit: 4
    t.integer  "product_id",  limit: 4
    t.integer  "login_id",    limit: 4
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
  end

  add_index "join_table_categories_products", ["category_id"], name: "index_join_table_categories_products_on_category_id", using: :btree
  add_index "join_table_categories_products", ["product_id"], name: "index_join_table_categories_products_on_product_id", using: :btree

  create_table "logins", force: :cascade do |t|
    t.string   "username",              limit: 255
    t.string   "key",                   limit: 255
    t.integer  "store_id",              limit: 4
    t.datetime "created_at",                                        null: false
    t.datetime "updated_at",                                        null: false
    t.string   "store_url",             limit: 255
    t.boolean  "categories_parsed",                 default: false
    t.string   "target_url",            limit: 255
    t.string   "email",                 limit: 255
    t.integer  "vendor_id",             limit: 4
    t.integer  "counter",               limit: 4
    t.integer  "magento_product_count", limit: 4
  end

  add_index "logins", ["vendor_id"], name: "index_logins_on_vendor_id", using: :btree

  create_table "product_images", force: :cascade do |t|
    t.integer  "product_id", limit: 4
    t.string   "img_url",    limit: 255
    t.integer  "login_id",   limit: 4
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "product_images", ["product_id"], name: "index_product_images_on_product_id", using: :btree

  create_table "products", force: :cascade do |t|
    t.integer  "product_id",         limit: 4
    t.string   "prod_type",          limit: 255
    t.string   "sku",                limit: 255
    t.string   "name",               limit: 255
    t.string   "ean",                limit: 255
    t.text     "description",        limit: 65535
    t.string   "price",              limit: 255
    t.string   "special_price",      limit: 255
    t.string   "special_from_date",  limit: 255
    t.string   "special_to_date",    limit: 255
    t.string   "url_key",            limit: 255
    t.string   "image",              limit: 255
    t.string   "color",              limit: 255
    t.string   "status",             limit: 255
    t.string   "weight",             limit: 255
    t.string   "set",                limit: 255
    t.string   "size",               limit: 255
    t.integer  "login_id",           limit: 4
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
    t.integer  "shopify_product_id", limit: 8
  end

  add_index "products", ["product_id"], name: "index_products_on_product_id", using: :btree

  create_table "sessions", force: :cascade do |t|
    t.string   "session_id", limit: 255,   null: false
    t.text     "data",       limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], name: "index_sessions_on_session_id", unique: true, using: :btree
  add_index "sessions", ["updated_at"], name: "index_sessions_on_updated_at", using: :btree

  create_table "shops", force: :cascade do |t|
    t.string   "shopify_domain", limit: 255, null: false
    t.string   "shopify_token",  limit: 255, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "shops", ["shopify_domain"], name: "index_shops_on_shopify_domain", unique: true, using: :btree

  create_table "target_category_imports", force: :cascade do |t|
    t.integer  "magento_category_id", limit: 4
    t.integer  "shopify_category_id", limit: 4
    t.integer  "login_id",            limit: 4
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
  end

  add_index "target_category_imports", ["magento_category_id"], name: "index_target_category_imports_on_magento_category_id", using: :btree
  add_index "target_category_imports", ["shopify_category_id"], name: "index_target_category_imports_on_shopify_category_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email",                  limit: 255, default: "", null: false
    t.string   "encrypted_password",     limit: 255, default: "", null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          limit: 4,   default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.datetime "created_at",                                      null: false
    t.datetime "updated_at",                                      null: false
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

  create_table "vendors", force: :cascade do |t|
    t.string   "email",                  limit: 255, default: "", null: false
    t.string   "encrypted_password",     limit: 255, default: "", null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          limit: 4,   default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.datetime "created_at",                                      null: false
    t.datetime "updated_at",                                      null: false
  end

  add_index "vendors", ["email"], name: "index_vendors_on_email", unique: true, using: :btree
  add_index "vendors", ["reset_password_token"], name: "index_vendors_on_reset_password_token", unique: true, using: :btree

end
