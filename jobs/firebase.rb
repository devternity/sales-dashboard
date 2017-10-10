require 'json'
require 'yaml'
require 'date'

###########################################################################
# Load configuration parameters.
###########################################################################

$global_config = YAML.load_file('./config/devternity.yml')
$firebase_config = JSON.parse(open($global_config['firebase_config']) {|f| f.read})

###########################################################################

require 'pry'
require 'pry-byebug'
require 'firebase'

class DTFBClient
  attr_reader :client

  def initialize(opts)
    base_url = "https://#{opts["project_id"]}.firebaseio.com/"
    auth_token = opts["auth_token"]

    @client = Firebase::Client.new(base_url, auth_token)
  end

  #private
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
              "company" => application["companyName"],
              "orders" => application["orders"].select {|order| order}
                              .map {|order|
                                {
                                    "title" => order["headline"],
                                    "tickets" => order["tickets"].is_a?(Hash) ? order["tickets"].values : order["tickets"]
                                }}
          }
      ]
    }.to_h
  end

  def counts(data = clean_applications())
    company_tickets = Hash.new(0)
    tickets = Hash.new(0)
    titles = Hash.new(0)

    counter = -> data {
      counted = Hash.new(0)
      data.each {|h| counted[h] += 1}
      counted = Hash[counted.map {|k, v| [k, v]}]
      counted
    }

    merger = -> totals, adds {
      adds.each {|key, value| totals[key] += value}
      totals
    }

    data.each do |id, application|
      order_tickets = application["orders"].map {|order| order["tickets"]}.select {|tickets| tickets}.flatten.map {|name| name || '<<NULL>>'}
      ticket_counters = counter.call(order_tickets)
      tickets = merger.call(tickets, ticket_counters)

      order_titles = application["orders"].map {|order| order["title"]}.map {|title| normalize_title(title)}.select {|title| title}.flatten
      title_counters = counter.call(order_titles)
      titles = merger.call(titles, title_counters)

      totals = ticket_counters.values.inject(0, :+)

      company_tickets[normalize_company(application["company"])] += totals
    end

    {"companies" => company_tickets, "tickets" => tickets, "titles" => titles, "total" => tickets.values.inject(0, :+)}
  end

  def normalize_title(title)
    return '<<NULL>>' unless title
    title.split('@')[0].strip.downcase
  end

  def normalize_company(name)
    return '<<NULL>>' unless name
    name.strip.upcase
        .gsub(/"/, '')
        .split(' ')
        .reject {|el| /^SIA$/.match(el)}
        .reject {|el| /^GMBH$/.match(el)}
        .reject {|el| /^AS$/.match(el)}
        .reject {|el| /^AB$/.match(el)}
        .reject {|el| /^LTD$/.match(el)}
        .reject {|el| /^UG$/.match(el)}
        .join(' ')
  end
end

$client = DTFBClient.new($firebase_config)
binding.pry
$client.counts()