class Auth < AuthenticatedController
   def self.shopify
        # current_shop = Shop.find_by( shopify_domain: login.target_url )
        # domain = current_shop.shopify_domain
        # token = current_shop.shopify_token
        # domain = "demo-magic.myshopify.com"
        # token = "3b9cdf02bdee2dbc8cd2b20d13a8b861"
        domain = "magic-streetwear.myshopify.com"
        token = "9b98e983ff7e7470a1d2e223cbfd4d1a"
        session = ShopifyAPI::Session.new(domain, token)
        ShopifyAPI::Base.activate_session(session)
   end 
end