class Login < ActiveRecord::Base
    before_save :check_login_count
    
    def check_login_count
        Login.delete_all if Login.all.count > 0
    end
end
