namespace :background_task do
  desc "start SIDEKIQ"
  task sidekiq_start: :environment do
    system 'RAILS_ENV=production bundle exec sidekiq ... -L log/sidekiq.log'
  end
  
  
end
