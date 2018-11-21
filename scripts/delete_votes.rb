
require 'active_support/core_ext/enumerable'
require 'active_support/time'
require 'json'
require 'yaml'
require 'date'
require 'firebase'

$firebase_json = File.open('./config/firebase-voting.json') { |file| file.read }
$firebase_config = JSON.parse($firebase_json)
$base_url = "https://#{$firebase_config['project_id']}.firebaseio.com/"
$firebase_client = Firebase::Client.new($base_url, $firebase_json)

$firebase_client.delete("votes")

