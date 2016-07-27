Rails.application.routes.draw do
  devise_for :vendors, :skip => :authenticated
  mount Delayed::Web::Engine, at: '/jobs'
  # require 'sidekiq/web'
  
  controller :sessions do
    get 'login' => :new, :as => :login
    post 'login' => :create, :as => :authenticate
    get 'auth/shopify/callback' => :callback
    get 'logout' => :destroy, :as => :logout
  end
  
  get  "logins",                      to: "login#login"
  post "logins",                      to: "login#create"
  get  "success_page",                to: "login#success_page"
  get  "error_page",                  to: "login#error_page"
  get  "category_parsing",            to: "parsing#category",                   as: "category_parsing"
  get  "parsing_categories_start",    to: "parsing#parsing_categories_start"
  get  "category_product_join_table", to: "parsing#category_product_join_table"
  get  'check_categories_parsing',    to: 'parsing#check_categories_parsing'
  post 'accepted_collection',         to: 'parsing#accepted_collection'
  get  'finish_page',                 to: 'parsing#finish_page'
  get  'exists_login/:login_id',      to: 'parsing#exists_login',               as: 'exists_login'
  get  'in_process',          to: 'parsing#in_process'
  
  # mount Sidekiq::Web, at: '/sidekiq'

  root :to => 'home#index'
end
