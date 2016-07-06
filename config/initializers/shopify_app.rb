ShopifyApp.configure do |config|
  config.api_key = "e94c616fc3c4c3ac8611dbe2e8c9608b"
  config.secret = "83e831acf036f45437ddbe2c4c244851"
  config.redirect_uri = "http://test-app-developerweb.c9users.io/auth/shopify/callback"
  config.scope = "read_orders, read_products, write_products"
  config.embedded_app = true
end
