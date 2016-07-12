class Login < ActiveRecord::Base
    before_save   :check_login_count
    before_create :check_url
    
    def check_login_count
        Login.delete_all if Login.all.count == 50
    end
    
    def check_url
        self.target_url.gsub!(/^(https?):\/\//, "").split('/')[0]
    end
end
