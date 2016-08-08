namespace :email do
  desc "testing of sucess email"
  task test: :environment do
    UserMailer.letter("ivanfadeev91@gmail.com").deliver
  end
  
  desc 'testing of email with error import'
  task test_error_import: :environment do
    UserMailer.error("deech with import", 'Import').deliver
  end
  
  desc 'testing of email with error monitoring'
  task test_error_monitoring: :environment do
    UserMailer.error("deech with monitoring", 'Monitoring').deliver
  end
end
