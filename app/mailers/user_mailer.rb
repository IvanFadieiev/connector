class UserMailer < ApplicationMailer
    default from: ENV['EMAIL_ADDR']
    
    def letter(email)
        if email
            mail(to: email, subject: 'Import of DB')
        end
    end
    
    def error(e)
        @error = e
        mail(to: 'ivanfadeev91@gmail.com', subject: 'ERROR with Import of DB')        
    end
end
