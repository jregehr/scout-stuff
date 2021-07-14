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

def parse_time_slot(time_slots)

  return "" if de_nil(time_slots).length() < 2

  # Same badge all six days 
  return "\"#{time_slots[1]}\"" if (!time_slots[1].nil? && time_slots[1].start_with?('Trail To First Class')) || (!has_nils(time_slots[1,6]) && de_nil(time_slots[1,6]).uniq.length() == 1)

  if count_sames(time_slots) > 3
    return do_sames(time_slots)

  end

  slot = "\""

  if !has_nils(time_slots[1,3]) && de_nil(time_slots[1,3]).uniq.length() == 1
    slot += "#{time_slots[1]}-2"
  else
    slot += three_slot_split(2, time_slots[1,3])
  end

  slot2 = ""
  if !has_nils(time_slots[4,3]) && de_nil(time_slots[4,3]).uniq.length() == 1
    slot2 = "#{time_slots[4]}-6"
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
  result += "  " if !result.empty? && !slots[1].nil?
  result += "#{slots[1]}-#{start_num+1}" if !slots[1].nil? && !slots[1].empty?
  result += "  " if !slots[1].nil? && !slots[1].empty?
  result += "#{slots[2]}-#{start_num+2}" if !slots[2].nil? && !slots[2].empty?

  return result

end

def find_time_slot(time_slot, input_table)

  input_table.each do |row|
    return row if row[0] == time_slot
  end
  return nil

end

def parse_intput_file(input_file, output_file)
  input_table = CSV.read(input_file)

  if input_table[1].join(",") != ',Day 2 - 07/17/2021,Day 4 - 07/19/2021,Day 5 - 07/20/2021,Day 6 - 07/21/2021,Day 7 - 07/22/2021,Day 8 - 07/23/2021'
    STDOUT.puts "Error in #{input_file}: Unknown schedule days: #{input_table[1].join(",")}"
    return
  end
  
  name_blag = input_table[0][0].split(' ')
  # kid_name = "\"#{name_blag[0]} #{name_blag[1][0,1]}\""
  kid_name = "\"#{name_blag[0]} #{name_blag[1]}\""
  output_file.puts(kid_name)
  
  time_slots = ["08:00 AM", "08:30 AM", "09:30 AM", "10:00 AM", "02:00 PM", "03:00 PM", "03:30 PM"]

  time_slots.each do |slot|
    row_badges = ""
    slot_row = find_time_slot(slot, input_table[2,6])
    if !slot_row.nil?
      row_badges = parse_time_slot(slot_row)
    end
      output_file.puts("\"#{slot[0,5].sub!(/^0?/, "")}\",#{row_badges}")
  end

end

check_params

input_folder = ENV["CAMPER_SCHEDULES"]
output_folder = ENV["OUTPUT_FOLDER"]
current_date = DateTime.now.strftime "%Y-%m-%d_%H-%M-%S"

open("#{output_folder}/schedules_#{current_date}.csv", 'w+') do |output_file|

  STDOUT.puts "To process: #{Dir["#{input_folder}/*.csv"].length()}"

  Dir["#{input_folder}/*.csv"].each do |input_file|

    STDOUT.puts "File: #{File.basename(input_file)}"
    parse_intput_file input_file, output_file
    
  
  end     # Dir[input_folder].each do |input_file|

end       # open("outputs/schedules_#{current_date}.csv", 'w+') do |output_file|