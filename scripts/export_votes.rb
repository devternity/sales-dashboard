
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

# response = $firebase_client.get("votes", { 'orderBy' => '"color"', 'equalTo' => '"green"' })

from = Time.now.in_time_zone('Europe/Riga').beginning_of_day
to   = Time.now.in_time_zone('Europe/Riga').end_of_day
response = $firebase_client.get("votes", { 'orderBy' => '"created"', 'startAt' => from.to_i, 'endAt' => to.to_i })

puts "FROM #{from.to_i} TO #{to.to_i}"

if !response.success?
  puts "Error #{response.code} (#{response.body})"
else
  puts JSON.pretty_generate(response.body)
end

