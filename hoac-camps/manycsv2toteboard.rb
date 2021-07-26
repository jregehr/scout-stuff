#!/usr/bin/env ruby

######################################################################################
#  This script will read a directory full of CSV files and build a camper schedule   #
# that can be printed as a large tote board for easy viewing in camp.                #
#                                                                                    #
# 2021 notes - the script has some issues and several campers from 2021 did not have #
# a correct schedule. Evan H and Jack S are examples.                                #
######################################################################################

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
  print_time = " (#{time_slots[0][0,5].sub!(/^0?/, "")})" if !time_slots[0].empty? && time != time_slots[0]

  # Same badge all six days 
  return "\"#{time_slots[1]}#{print_time}\"" if (!time_slots[1].nil? && time_slots[1].start_with?('Trail To First Class')) || (!has_nils(time_slots[1,6]) && de_nil(time_slots[1,6]).uniq.length() == 1)

  if count_sames(time_slots) > 3
    return do_sames(time_slots)

  end

  slot = "\""

  if !has_nils(time_slots[1,3]) && de_nil(time_slots[1,3]).uniq.length() == 1
    slot += "#{time_slots[1]}#{print_time}"
  else
    slot += three_slot_split(2, time_slots[1,3])
  end

  slot2 = ""
  if !has_nils(time_slots[4,3]) && de_nil(time_slots[4,3]).uniq.length() == 1
    slot2 = "#{time_slots[4]}#{print_time}"
  else
    slot2 = three_slot_split(6, time_slots[4,3])
  end

  slot += " / #{slot2}" if !slot2.empty? 

  slot += "\""
  return slot

end

def de_nil(an_array)
  return an_array.reject { |e| e.to_s.empty? }
end

def has_nils(an_array)
  return an_array.include? nil
end

def count_sames(slots)
  count = 0
  2.upto(6) do |i|
    count += 1 if !slots[1].nil? && !slots[i].nil? &&  slots[1] == slots[i]
  end
  return count
end

def do_sames(slots)
  slot = "\""

  slot += slots[1]
  1.upto(5) do |i|
    slot += ", #{slots[i]}-#{i}" if slots[i] != slots[1]
  end

  slot += "\""
  return slot
end

def three_slot_split(start_num, slots)
  result = ''
  result += "#{slots[0]}-#{start_num}" if !slots[0].nil? && !slots[0].empty?
  result += ", " if !result.empty? && !slots[1].nil?
  result += "#{slots[1]}-#{start_num+1}" if !slots[1].nil? && !slots[1].empty?
  result += ", " if !slots[1].nil? && !slots[1].empty?
  result += "#{slots[2]}-#{start_num+2}" if !slots[2].nil? && !slots[2].empty?

  return result

  # return "FIXME: #{slots[0]} (Day #{start_num})"
end

def parse_intput_file(input_file, output_file)
  input_table = CSV.read(input_file)

  if input_table[1].join(",") != ',Day 2 - 07/17/2021,Day 4 - 07/19/2021,Day 5 - 07/20/2021,Day 6 - 07/21/2021,Day 7 - 07/22/2021,Day 8 - 07/23/2021'
    STDOUT.puts "Error in #{input_file}: Unknown schedule days: #{input_table[1].join(",")}"
    return
  end
  
  name_blag = input_table[0][0].split(' ')
  kid_name = "\"#{name_blag[0]} #{name_blag[1][0,1]}\""
  sort = "\"#{name_blag[1][0,1]}_#{name_blag[0]}\""
  
  the_slot = 2

  session_1 = ""
  session_2 = ""
  session_3 = ""
  session_4 = ""

  if ["08:00 AM", "08:30 AM"].include? input_table[the_slot][0]
    session_1 = parse_time_slot("08:30 AM", input_table[the_slot])
    the_slot += 1
  end
  
  if ["09:30 AM", "10:00 AM"].include? input_table[the_slot][0]
    session_2 = parse_time_slot("09:30 AM", input_table[the_slot])
    the_slot += 1
  end

  if ["02:00 PM"].include? input_table[the_slot][0]
    session_3 = parse_time_slot("02:00 PM", input_table[the_slot])
    the_slot += 1
  end

  if ["03:00 PM", "03:30 PM"].include? input_table[the_slot][0]
    session_4 = parse_time_slot("03:00 PM", input_table[the_slot])
  end

  output_file.puts "#{kid_name},#{sort},#{session_1},#{session_2},#{session_3},#{session_4}"

end

check_params

input_folder = ENV["CAMPER_SCHEDULES"]
output_folder = ENV["OUTPUT_FOLDER"]
current_date = DateTime.now.strftime "%Y-%m-%d_%H-%M-%S"

open("#{output_folder}/tote-board_#{current_date}.csv", 'w+') do |file|

  file.puts ',,"Day 2-5 / 6-8",,,,Notes /'
  file.puts 'Name,SORT,8:30,9:30,2:00,3:00,Rank Advancement'

  Dir["#{input_folder}/*.csv"].each do |input_file|

    STDOUT.puts "File: #{File.basename(input_file)}"
    parse_intput_file input_file, file
    
  
  end     # Dir[input_folder].each do |input_file|

end       # open("outputs/tote-board_#{current_date}.csv", 'w+') do |file|