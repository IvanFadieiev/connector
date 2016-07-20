class Login < ActiveRecord::Base
    # before_save   :check_login_count
    before_create :check_url
    validates_presence_of :username, :key, :store_id, :store_url, :target_url
    
    def check_login_count
        Login.delete_all if Login.all.count == 50
    end
    
    def check_url
        if self.target_url.include?("http") 
            self.target_url.gsub!(/^(https?):\/\//, "").split('/')[0]
        end
    end
end
