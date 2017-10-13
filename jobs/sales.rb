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

#require 'pry'
#require 'pry-byebug'
require 'firebase'

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
      send_event('companies', {title: 'Companies top 15', moreinfo: "Total #{sales[:companies].size}", items: sales[:companies].sort_by { |name, count| -count }.take(15).map {|name, count| {label: name, value: count}}})
      send_event('titles',    {title: 'Titles top 15', moreinfo: "Total #{sales[:titles].size}", items: sales[:titles].sort_by { |name, count| -count  }.take(15).map {|name, count| {label: name, value: count}}})
      send_event('tickets',   {moreinfo: "Total #{sales[:total]}", items: sales[:tickets].sort_by {|name, count| -count}.map {|name, count| {label: name, value: count}}})
      day1Tickets = sales[:tickets]["KEYNOTES_(DAY_I)"]
      send_event('keynotes', {moreinfo: "#{day1Tickets}/#{600}", value: day1Tickets})
      send_event('workshops', {moreinfo: "#{sales[:total] - day1Tickets}/#{350}", value: sales[:total] - day1Tickets})
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
    data.map {|id, application|
      [
          id,
          {
              company: application['companyName'],
              orders: application['orders'].select {|order| order}
                              .map {|order|
                                {
                                    title: order['headline'],
                                    tickets: order['tickets'].is_a?(Hash) ? order['tickets'].values : order['tickets']
                                }}
          }
      ]
    }.to_h
  end

  def counts(data = clean_applications())
    company_tickets = Hash.new(0)
    tickets = Hash.new(0)
    titles = Hash.new(0)

    counter = -> hash {
      counted = Hash.new(0)
      hash.each {|h| counted[h] += 1}
      counted = Hash[counted.map {|k, v| [k, v]}]
      counted
    }

    merger = -> totals, adds {
      adds.each {|key, value| totals[key] += value}
      totals
    }

    data.each do |id, application|
      order_tickets = application[:orders].map {|order| order[:tickets]}.select {|t| t}.flatten.select {|t| t}
      ticket_counters = counter.call(order_tickets)
      tickets = merger.call(tickets, ticket_counters)

      order_titles = application[:orders].map {|order| order[:title]}.map {|title| normalize_title(title)}.select {|title| title}.flatten
      title_counters = counter.call(order_titles)
      titles = merger.call(titles, title_counters)

      totals = ticket_counters.values.inject(0, :+)

      company_tickets[normalize_company(application[:company])] += totals
    end

    {companies: company_tickets, tickets: tickets, titles: titles, total: tickets.values.inject(0, :+)}
  end

  def normalize_title(title)
    return '-- ' unless title
    result = title.downcase
        .split('@')[0].strip
        .split(' at ')[0].strip
        .gsub(/^.*?izstrādātājs.*$/, 'software developer')
        .gsub(/^.*?vadītājs.*$/, 'manager')
        .gsub(/padawan\s*/, '') 
        .gsub(/engineer/, 'developer')
        .gsub(/havi/, 'developer')
        .gsub(/mintos/, 'developer')        
        .gsub(/^developer$/, 'software developer')        
        .gsub(/^architect$/, 'software architect')        
    result                                     
  end

  def normalize_company(name)
    return '-- ' unless name
    result = name.strip.upcase
        .gsub(/"/, '')
        .gsub(/\./, '')
        .gsub(/-/, ' ')
        .gsub(/”/, ' ')
        .split(' ')
        .reject {|el| /^SHARED$/.match(el)}
        .reject {|el| /^SERVICE$/.match(el)}
        .reject {|el| /^CENTER$/.match(el)}
        .reject {|el| /^COMPETENCE$/.match(el)}
        .reject {|el| /^CONSULTING$/.match(el)}
        .reject {|el| /^CLOUD$/.match(el)}
        .reject {|el| /^LATVIA$/.match(el)}
        .reject {|el| /^OY$/.match(el)}
        .reject {|el| /^IT$/.match(el)}
        .reject {|el| /^SIA$/.match(el)}
        .reject {|el| /^GMBH$/.match(el)}
        .reject {|el| /^AS$/.match(el)}
        .reject {|el| /^AB$/.match(el)}
        .reject {|el| /^LTD$/.match(el)}
        .reject {|el| /^UG$/.match(el)}
        .join(' ')
    result = 'IF P&C' if /IF P&C/.match(result)
    result
  end
end

SCHEDULER.every '1m', DevternityFirebaseStats.new($firebase_config)
SCHEDULER.at Time.now, DevternityFirebaseStats.new($firebase_config)
