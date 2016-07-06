ShopifyApp.configure do |config|
  config.api_key = "e94c616fc3c4c3ac8611dbe2e8c9608b"
  config.secret = "f12c7ca57f44556f418cf1b89ea5aadd"
  config.redirect_uri = "https://test-app-developerweb.c9users.io/auth/shopify/callback"
  config.scope = "read_orders, read_products, write_products"
  config.embedded_app = true
end
