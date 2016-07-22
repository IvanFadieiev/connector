class ApplicationMailer < ActionMailer::Base
  default from: ENV['EMAIL_ADDR']
  layout 'mailer'
end
