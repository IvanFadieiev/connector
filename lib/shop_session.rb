module ShopSession
    def new_with(login)
        current_shop = Shop.find_by( shopify_domain: login.target_url )
        # ShopifyAPI::Session.new
        domain =current_shop.shopify_domain
        token = current_shop.shopify_token
        session = ShopifyAPI::Session.new(domain, token)
        ShopifyAPI::Base.activate_session(session)
        # ShopifyAPI::Base.clear_session
    end
end