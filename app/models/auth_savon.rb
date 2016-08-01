class AuthSavon
    def self.connect( login )
        $client  = Savon.client(wsdl: login.store_url + "/api/v2_soap?wsdl" )
        $request = $client.call( :login, message:{ magento_username: login.username, key: login.key } )
        $session = $request.body[:login_response][:login_return]
    end
end