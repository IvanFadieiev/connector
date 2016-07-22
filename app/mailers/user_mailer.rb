class UserMailer < ApplicationMailer
    default from: ENV['EMAIL_ADDR']
    
    def letter(email)
        if email
            mail(to: email, subject: 'Import of DB')
        end
    end
end
