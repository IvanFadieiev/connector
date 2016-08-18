class UserMailer < ApplicationMailer
    default from: ENV['EMAIL_ADDR']
    
    def letter(email)
        if email
            mail(to: email, subject: 'Import of DB')
        end
    end
    
    def error(e, msg)
        @proccess = msg
        @error = e
        mail(to: 'mshconnector@gmail.com', subject: "ERROR with #{msg} of DB")        
    end
    
    def monitoring(e, msg)
        @proccess = msg
        @error = e
        mail(to: 'mshconnector@gmail.com', subject: "#{msg} of DB")
    end
end
