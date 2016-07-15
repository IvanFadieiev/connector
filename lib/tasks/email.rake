namespace :email do
  desc "TODO"
  task test: :environment do
    UserMailer.letter(Login.last).deliver_now
  end

end
