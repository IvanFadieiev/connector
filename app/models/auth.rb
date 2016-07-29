class Auth < AuthenticatedController
   def self.shopify
        domain = "magic-streetwear.myshopify.com"
        token = "9b98e983ff7e7470a1d2e223cbfd4d1a"
        session = ShopifyAPI::Session.new(domain, token)
        ShopifyAPI::Base.activate_session(session)
   end 
end