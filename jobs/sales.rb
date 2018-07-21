# encoding: utf-8

require 'json'
require 'yaml'
require 'date'

###########################################################################
# Load configuration parameters.
###########################################################################

$global_config = YAML.load_file('./config/devternity.yml')
$firebase_config = JSON.parse(open($global_config['firebase_config']) {|f| f.read})

###########################################################################

# require 'pry'
# require 'pry-byebug'
require 'firebase'

DT2018_PRODUCTS = ['DT_RIX_18']
DT2018_DAY1_KEYNOTE = 'Main Day Pass'

class DevternityFirebaseStats
  attr_reader :client

  def initialize(opts)
    base_url = "https://#{opts['project_id']}.firebaseio.com/"
    auth_token = opts['auth_token']

    @client = Firebase::Client.new(base_url, auth_token)
  end

  def call(job)
    begin
      sales = counts()
      event_stats = sales[:tickets].sort_by {|name, count| -count}.map {|name, count| {label: name, value: count}}
      send_event('tickets', {title: "#{sales[:total]} tickets purchased", moreinfo: "Total #{sales[:total]}", items: event_stats})
      day1Tickets = sales[:tickets][DT2018_DAY1_KEYNOTE]
      send_event('keynotes', {moreinfo: "#{day1Tickets}/#{600}", value: day1Tickets})
      send_event('workshops', {moreinfo: "#{sales[:total] - day1Tickets}/#{200}", value: sales[:total] - day1Tickets})
    end
  rescue => e
    puts e.backtrace
    puts "\e[33mFor the Firebase credentials check ./config/firebase-legacy.json.\n\tError: #{e.message}\e[0m"
  end

  private
  def raw_applications
    response = @client.get('/applications')
    raise Error.new "DT error #{response.code}" unless response.success?
    response.body
  end

  def clean_applications(data = raw_applications())
    dt2018_data = data.select {|id, application| DT2018_PRODUCTS.include?(application['product']) }
    dt2018_data.map {|id, application|
      tickets = application['tickets'] || [DT2018_DAY1_KEYNOTE]
      tickets = [tickets] unless tickets.is_a? Array
      tickets = tickets.map {|ticket| ticket['event'] || DT2018_DAY1_KEYNOTE}

      [ id, { tickets: tickets }]
    }.to_h
  end

  def counts(data = clean_applications())
    tickets = Hash.new(0)

    counter = -> names {
      counted = Hash.new(0)
      names.each {|h| counted[h] += 1}
      counted = Hash[counted.map {|k, v| [k, v]}]
      counted
    }

    merger = -> totals, adds {
      adds.each {|key, value| totals[key] += value}
      totals
    }

    data.each do |id, application|
      order_tickets = application[:tickets].flatten
      ticket_counters = counter.call(order_tickets)
      tickets = merger.call(tickets, ticket_counters)

      totals = ticket_counters.values.inject(0, :+)  
    end

    {tickets: tickets, total: tickets.values.inject(0, :+)}
  end

end

SCHEDULER.every '1m', DevternityFirebaseStats.new($firebase_config)
SCHEDULER.at Time.now, DevternityFirebaseStats.new($firebase_config)
