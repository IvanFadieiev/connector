namespace :email do
  desc "testing of sucess email"
  task test: :environment do
    UserMailer.letter("ivanfadeev91@gmail.com").deliver
  end
  
  desc 'testing of email with error'
  task test_error: :environment do
    UserMailer.error("deech").deliver
  end
end
