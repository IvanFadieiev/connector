namespace :email do
  desc "testing of email"
  task test: :environment do
    UserMailer.letter("ivanfadeev91@gmail.com").deliver
  end
end
