set :deploy_to, '/var/www/vhosts/webiprog.com/connector.webiprog.com'
set :rails_env, :production
set :branch, :master

server '74.208.149.133', roles: %w{web app db}, user: 'webiprog_com'
 