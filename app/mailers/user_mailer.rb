class UserMailer < ApplicationMailer
    default from: "ivanfadeev91@gmail.com"
    
    def letter(login)
        if login.email
            mail(to: login.email, subject: 'Import of DB')
        end
    end
end
