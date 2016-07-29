module ShopSession
    # create connect to shopify shop
    def reconnect_new_with(login)
        current_shop = Shop.find_by( shopify_domain: "magic-streetwear.myshopify.com" )
        domain = "magic-streetwear.myshopify.com"
        token = "9de6ff262c083f364e28980349ca685a"
        session = ShopifyAPI::Session.new(domain, token)
        ShopifyAPI::Base.activate_session(session)
    end
end