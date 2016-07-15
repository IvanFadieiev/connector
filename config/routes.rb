Rails.application.routes.draw do
  # mount Delayed::Web::Engine, at: '/jobs'
  require 'sidekiq/web'
  
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
  get  "category_parsing",            to: "parsing#category", as: "category_parsing"
  get  "parsing_categories_start",    to: "parsing#parsing_categories_start"
  get  "category_product_join_table", to: "parsing#category_product_join_table"
  get  'check_categories_parsing',    to: 'parsing#check_categories_parsing'
  post 'accepted_collection',         to: 'parsing#accepted_collection'
  get  'finish_page',                 to: 'parsing#finish_page'

  mount Sidekiq::Web, at: '/sidekiq'

  root :to => 'home#index'
  
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
