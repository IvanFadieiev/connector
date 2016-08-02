class Auth < AuthenticatedController
   def self.shopify(login)
        current_shop = Shop.find_by( shopify_domain: login.target_url )
        domain = current_shop.shopify_domain
        token = current_shop.shopify_token
        session = ShopifyAPI::Session.new(domain, token)
        ShopifyAPI::Base.activate_session(session)
   end 
end