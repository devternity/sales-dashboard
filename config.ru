
require 'active_support'
require 'dashing'
require 'yaml'

$global_config = YAML.load_file('./config/integrations.yml')

configure do
  set :auth_token, 'YOUR_AUTH_TOKEN'

  helpers do

    def protected!
      unless authorized?
        response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
        throw(:halt, [401, "Not authorized\n"])
      end
    end

    def authorized?
      @auth ||=  Rack::Auth::Basic::Request.new(request.env)
      @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == [$global_config['dashboard_username'], $global_config['dashboard_password']]
    end

  end
end

map Sinatra::Application.assets_prefix do
  run Sinatra::Application.sprockets
end

run Sinatra::Application
