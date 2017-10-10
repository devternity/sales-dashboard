require 'json'
require 'yaml'
require 'date'

require 'net/http'
require 'open-uri'
require 'uri'

require "jwt"

###########################################################################
# Load configuration parameters.
###########################################################################

$global_config = YAML.load_file('./config/devternity.yml')
$oauth_config = JSON.parse(open($global_config['firebase_oauth']) { |f| f.read })


# Get your service account's email address and private key from the JSON key file
$service_account_email = $oauth_config['client_email']
$private_key = OpenSSL::PKey::RSA.new($oauth_config['private_key'])

def create_custom_token(uid, is_premium_account = false)
  now_seconds = Time.now.to_i
  payload = {:iss => $service_account_email,
             :sub => $service_account_email,
             :aud => "https://identitytoolkit.googleapis.com/google.identity.identitytoolkit.v1.IdentityToolkit",
             :iat => now_seconds,
             :exp => now_seconds + (60*60), # Maximum expiration time is one hour
             :uid => uid,
             :claims => {:premium_account => is_premium_account}}
  JWT.encode payload, $private_key, "RS256"
end

def aaget(path, token = create_custom_token($global_config['firebase_uid']))
  uri = URI.parse("https://#{$oauth_config["project_id"]}.firebaseio.com/#{path}.json")
  https = Net::HTTP.new(uri.host, uri.port)
  https.use_ssl = true
  req = Net::HTTP::Get.new(uri.path)
  req["Authorization"] = "Bearer #{token}"
  puts uri
  return https.request(req)
end

require 'pry'
require 'pry-byebug'

def aa
  test1 = aaget('applications')
  binding.pry
  puts test1
end

aa


