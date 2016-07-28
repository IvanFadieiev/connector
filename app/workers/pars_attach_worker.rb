class ParsAttachWorker
  # include Sidekiq::Worker
  def perform(id)
    login = Login.find(id)
    # login = Login.find(451)

    ParserProcess.new.parse_categories_attach_and_create_objects(login)
  end
end

