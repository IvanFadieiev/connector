# Dir[Rails.root + 'lib/**/*.rb'].each do |file|
  require Rails.root + 'lib/import.rb'
  require Rails.root + 'lib/parser.rb'
  require Rails.root + 'lib/parser_process.rb'
  require Rails.root + 'lib/shop_session.rb'
# end