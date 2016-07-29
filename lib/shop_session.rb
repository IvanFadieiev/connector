module ShopSession
    # create connect to shopify shop
    def reconnect_new_with(login)
        current_shop = Shop.find_by( shopify_domain: ENV['TARGET_URL'] )
        domain =current_shop.shopify_domain
        token = current_shop.shopify_token
        session = ShopifyAPI::Session.new(domain, token)
        ShopifyAPI::Base.activate_session(session)
    end
end