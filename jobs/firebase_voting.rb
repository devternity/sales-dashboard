# encoding: utf-8

require 'active_support/core_ext/enumerable'
require 'active_support/time'
require 'json'
require 'yaml'
require 'date'
require 'time'
require 'firebase'
require 'net/http'
require 'open-uri'
require 'uri'

###########################################################################
# Load configuration parameters.
###########################################################################

$global_config = YAML.load_file('./config/integrations.yml') || {}
$firebase_json = File.open('./config/firebase-voting.json') { |file| file.read }
$firebase_config = JSON.parse($firebase_json)
$base_url = "https://#{$firebase_config['project_id']}.firebaseio.com/"
$firebase_client = Firebase::Client.new($base_url, $firebase_json)

def raw_votes()
  response = $firebase_client.get("votes")
  raise "DT error #{response.code} (#{response.body})" unless response.success?
  response.body
end

def today_votes(votes = raw_votes())
  from = Time.now.in_time_zone('Europe/Riga').beginning_of_day
  to   = Time.now.in_time_zone('Europe/Riga').end_of_day
  votes.select { |id, vote| 
    !vote["created"].nil? && 
     vote["created"] >= from.to_i && 
     vote["created"] <= to.to_i 
  }
end

def group_by_device(votes = today_votes())
  votes.group_by { |id, vote| vote["device"] }
end

def group_by_color(votes = today_votes())
  votes.group_by { |id, vote| vote["color"] }
end

def group_by_time_slot(votes = today_votes(), time_slots = time_slots())
  votes.group_by { |id, vote|
    time_slots.find { |time_slot| 
      vote["created"] >= (time_slot[:end] - 20.minutes).to_f && 
      vote["created"] <= (time_slot[:end] + 20.minutes).to_f
    }
  }
end

def group_by_speech(track, votes = today_votes(), speeches = speeches())
  group_by_time_slot(votes)
    .select { |time_slot, _| !time_slot.nil? }    # filter votes that didn't match any time slot
    .map { |time_slot, track_votes|               # convert time slot from "{ :start => _, :end => _ }" format into "HH:MM"
      [ 
        time_slot[:start].strftime("%H:%M"), 
        track_votes 
      ] 
    }
    .to_h
    .select { |time_slot, _|                      # select only slots that exist in the speech list for given track
      speeches[track].key?(time_slot) 
    } 
end

def group_by_track(votes = today_votes())
  device_track_mapping = { 
    "track1": [ "test_1", "test_4" ], 
    "track2": [ "test_2" ], 
    "track3": [ "test_3" ]
  }
  votes_by_device = group_by_device(votes)
  votes_by_track = { "track1": [], "track2": [], "track3": [] }
  device_track_mapping.each do |track, devices|
    devices.each do |device|
      votes_by_track[track] += votes_by_device[device]
    end
  end  
  return votes_by_track
end

def time_slots(schedule = schedule())
  schedule
    .map { |entry| entry['time'] }                # select slot starting times 
    .map { |time| format_time(time) }             # format it as "HH:MM"
    .uniq
    .sort
    .map { |time|                                 # convert to Time objects in Riga time zone 
      Time.parse(
        time, 
        Time.now.in_time_zone('Europe/Riga')
      ) 
    }
    .each_cons(2)                                 # iterate over pairs of consecutive times
    .map { |a| { "start": a[0], "end": a[1] } }   # convert pairs to "{ :start => _, :end => _ }" format
end

def format_time(time_str)
  if time_str.length == 4 
    return "0#{time_str}" 
  else              	
    return time_str
  end
end

def schedule
  JSON.parse(open($global_config['devternity_data_file']) { |f| f.read })
    .first['program']
    .find { |e| e['event'] == 'keynotes' }['schedule']
end

def speeches(schedule = schedule())
  track1 = {}
  track2 = {}
  track3 = {}
  schedule
    .select { |time_slot| time_slot['type'] == 'speech' }
    .each do |time_slot|
      key = format_time(time_slot['time'])     
      if track1[key].nil?
        track1[key] = time_slot_to_obj(time_slot)
      elsif track2[key].nil?
        track2[key] = time_slot_to_obj(time_slot)
      elsif track3[key].nil?
        track3[key] = time_slot_to_obj(time_slot)
      end
    end
  { "track1": track1, "track2": track2, "track3": track3 }
end

def time_slot_to_obj(time_slot) 
  { 
    :name      => time_slot['name'],
    :title     => time_slot['title'],
    :img       => 'http://devternity.com/' + time_slot['img']
  }
end

COLORS = [
  "#ff0000",
  "#f52d05",
  "#ec550a",
  "#e2780e",
  "#d89612",
  "#cfb015",
  "#c5c518",
  "#a1bb1b",
  "#80b21d",
  "#63a81f",
  "#4a9e20",
  "#359521",
  "#228b22"
]

###########################################################################
# Job's schedules.
###########################################################################

SCHEDULER.every '1m', :first_in => 0 do |job| 

  speeches = speeches(schedule())

  votes_by_track = group_by_track(today_votes(raw_votes()))
  votes_by_track.each do |track, track_votes|
    votes_by_track[track] = group_by_speech(track, track_votes, speeches)
    votes_by_track[track].each do |time_slot, slot_votes|
      slot_votes_by_color = group_by_color(slot_votes)
      green = (slot_votes_by_color["green"] || []).length
      red = (slot_votes_by_color["red"] || []).length
      yellow = (slot_votes_by_color["yellow"] || []).length
      optimistic = (2*green.to_f + yellow - 2*red) / (2*(green.to_f + red + yellow)) * 100
      optimisticPlus = (2*green.to_f + yellow - red) / (2*(green.to_f + red + yellow)) * 100
      pessimistic = (2*green.to_f - yellow - 2*red) / (2*(green.to_f + red + yellow)) * 100
      votes_by_track[track][time_slot] = {
        "img": speeches[track][time_slot][:img],
        "name": speeches[track][time_slot][:name],
        "title": speeches[track][time_slot][:title],
        "track": track,
        "time": time_slot,
        "total": green + red + yellow,
        "optimistic": optimistic,
        "optimisticPlus": optimisticPlus,
        "pessimistic": pessimistic,
        "color": COLORS[ [0, [(COLORS.length * optimisticPlus / 100).round, COLORS.length - 1].min].max ],
        "green": green, 
        "red": red, 
        "yellow": yellow
      }
    end
  end

  send_event('votes', { votes: votes_by_track })

  today_votes_by_color = group_by_color(today_votes(raw_votes()))
  send_event('greens', { current: (today_votes_by_color["green"] || []).length }) 

end
