class ParsCategoryWorker
  include Sidekiq::Worker
  def perform(id)
    login = Login.find(id)
    ParserProcess.new.parse_categories(login)
  end
end
