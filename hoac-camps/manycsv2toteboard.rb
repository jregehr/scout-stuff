#!/usr/bin/env ruby

require 'date'
require 'csv'

def check_params()
  camper_sched_missing = ENV["CAMPER_SCHEDULES"].nil? || ENV["CAMPER_SCHEDULES"].empty?
  output_folder_missing = ENV["OUTPUT_FOLDER"].nil? || ENV["OUTPUT_FOLDER"].empty?
  return if !camper_sched_missing && !output_folder_missing

  bad_things += "CAMPER_SCHEDULES" if camper_sched_missing
  bad_things += ", " if output_folder_missing && !camper_sched_missing
  bad_things += "OUTPUT_FOLDER" if output_folder_missing
  abort("Missing parameters: #{bad_things}")
end

def parse_time_slot(time, time_slots) #_maybe_nils)

  return "" if de_nil(time_slots).length() < 2

  print_time = ""

  # Different than the expected time
  print_time = " (#{time_slots[0][1,4]})" if !time_slots[0].empty? && time != time_slots[0]

  # Same badge all six days 
  return "\"#{time_slots[1]}#{print_time}\"" if de_nil(time_slots[1,6]).uniq.length() == 1

  slot = "\""

  if !has_nils(time_slots[1,3]) && de_nil(time_slots[1,3]).uniq.length() == 1
    slot += "#{time_slots[1]}#{print_time}"
  else
    slot += three_slot_split(1, time_slots[1,3])
  end

  slot += " / "

  if !has_nils(time_slots[4,3]) && de_nil(time_slots[4,3]).uniq.length() == 1
    slot += "#{time_slots[4]}#{print_time}"
  else
    slot += three_slot_split(4, time_slots[4,3])
  end

  slot += "\""
  return slot
  
  # STDOUT.puts "Too complex: #{time_slots}"
  # return "\"Too complex\""

end

def de_nil(an_array)
  return an_array.reject { |e| e.to_s.empty? }
end

def has_nils(an_array)
  return an_array.include? nil
end

def three_slot_split(start_num, slots)
  return "FIXME: #{slots[0]} (Day #{start_num})"
end

def parse_intput_file(input_file, output_file)
  input_table = CSV.read(input_file)

  if input_table[1].join(",") != ',Day 2 - 07/17/2021,Day 4 - 07/19/2021,Day 5 - 07/20/2021,Day 6 - 07/21/2021,Day 7 - 07/22/2021,Day 8 - 07/23/2021'
    STDOUT.puts "Error in #{input_file}: Unknown schedule days: #{input_table[1].join(",")}"
    return
  end
  
  name_blag = input_table[0][0].split(' ')
  kid_name = "\"#{name_blag[0]} #{name_blag[1][0,1]}\""
  
  session_1 = parse_time_slot("08:30 AM", input_table[2])
  session_2 = parse_time_slot("09:30 AM", input_table[3])
  session_3 = parse_time_slot("02:00 PM", input_table[4])
  session_4 = parse_time_slot("03:00 PM", input_table[5])

  output_file.puts "#{kid_name},#{session_1},#{session_2},#{session_3},#{session_4}"

end

check_params

input_folder = ENV["CAMPER_SCHEDULES"]
output_folder = ENV["OUTPUT_FOLDER"]
current_date = DateTime.now.strftime "%Y-%m-%d_%H-%M-%S"

open("#{output_folder}/tote-board_#{current_date}.csv", 'w+') do |file|

  file.puts ',"Day 1-3 / 4-6",,,,Notes/Rank Advancement'
  file.puts 'Name,8:30,9:30,2:00,3:00,'

  Dir["#{input_folder}/*.csv"].each do |input_file|

    # STDOUT.puts "File: #{input_file}"
    parse_intput_file input_file, file
    
  
  end     # Dir[input_folder].each do |input_file|

end       # open("outputs/tote-board_#{current_date}.csv", 'w+') do |file|