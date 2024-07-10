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
require 'json'

## Global variables - these may vary by year
schedule_days = ',Day 2 - 06/25/2024,Day 3 - 06/26/2024,Day 4 - 06/27/2024,Day 5 - 06/28/2024,Day 6 - 06/29/2024,Day 8 - 07/01/2024'
trail_to_first_class = 'Trail To First Class A1'

class_costs_file = "Class-Costs-"
class_costs_file += DateTime.now.strftime "%Y" 
class_costs_file += ".json"

def check_params(class_costs_file)
  camper_sched_missing = ENV["CAMPER_SCHEDULES"].nil? || ENV["CAMPER_SCHEDULES"].empty?
  output_folder_missing = ENV["OUTPUT_FOLDER"].nil? || ENV["OUTPUT_FOLDER"].empty?
  class_costs_file_missing = check_class_costs_file class_costs_file
  return if !camper_sched_missing && !output_folder_missing && !class_costs_file_missing

  bad_things = ''
  bad_things += "CAMPER_SCHEDULES" if camper_sched_missing
  bad_things += ", " if output_folder_missing && !camper_sched_missing
  bad_things += "OUTPUT_FOLDER" if output_folder_missing
  bad_things += ", " if (output_folder_missing || camper_sched_missing) && class_costs_file_missing
  bad_things += "CAMPER_SCHEDULES folder must contiain " if class_costs_file_missing
  bad_things += class_costs_file if class_costs_file_missing
  abort("Missing parameters: #{bad_things}")
end

def check_class_costs_file(class_costs_file)
  class_file = ENV["CAMPER_SCHEDULES"]
  class_file += "/../"
  class_file += class_costs_file
  return ! File.exists?(class_file)
end


def parse_time_slot(time, time_slots, session_slot) #_maybe_nils)
  # STDOUT.puts("=================")
  # STDOUT.puts("time:#{time}")
  # STDOUT.puts("time:#{time_slots}")
  # STDOUT.puts("session_slot:#{session_slot}")

  return "" if de_nil(time_slots).length() < 2

  print_time = ""

  # Different than the expected time
  print_time = " (#{time_slots[0][0,5].sub!(/^0?/, "")})" if !time_slots[0].empty? && time != time_slots[0]

  # Same badge all six days 
  return [ "#{time_slots[1]}#{print_time}" ] if (!time_slots[1].nil? && time_slots[1].start_with?('Trail To First Class')) || (!has_nils(time_slots[1,6]) && de_nil(time_slots[1,6]).uniq.length() == 1)

  if count_sames(time_slots) > 3
    session_slot[0] = do_sames(time_slots)
    return session_slot
  end

  if !has_nils(time_slots[1,3]) && de_nil(time_slots[1,3]).uniq.length() == 1
    session_slot[0] = "#{time_slots[1]}#{print_time}"
  else
    session_slot[0] = three_slot_split(2, time_slots[1,3])
  end

  # STDOUT.puts("pre-result: #{session_slot}")
  # STDOUT.puts("time_slots: #{time_slots}")
  # STDOUT.puts("has_nils(time_slots[4,3]): #{has_nils(time_slots[4,3])}")
  # STDOUT.puts("de_nil(time_slots[4,3]): #{de_nil(time_slots[4,3]).uniq.length()}")

  if de_nil(time_slots[4,3]).uniq.length() > 0
    if !has_nils(time_slots[4,3]) && de_nil(time_slots[4,3]).uniq.length() == 1
      session_slot[1] = "#{time_slots[4]}#{print_time}"
    else
      session_slot[1] = three_slot_split(6, time_slots[4,3])
    end
  end

  # STDOUT.puts("result: #{session_slot}")

  return session_slot

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
  slot = ''

  slot += slots[1]
  1.upto(5) do |i|
    slot += ", #{slots[i]}-#{i}" if slots[i] != slots[1]
  end

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

end

def session_output(session)

  if (session[0] == "" || session[0] == nil || session[0] == " ") && (session[1] == "" || session[1] == nil || session[1] == " ")
    return ""
  end

  if session[0] == "" || session[0] == " " || session[0] == nil
    STDOUT.puts("session[0] is empty, adding spaces")
    return "             / " + session[1]
  end
  
  return session.join(" / ")

end

def add_costs(session, class_costs)
  result = 0
  if session[0] != nil
    result = class_costs.fetch(session[0].split("-")[0], 0)
  end

  if session[1] != nil
    result += class_costs.fetch(session[1].split("-")[0], 0)
  end
  return result
end

def parse_input_file(input_file, output_file, schedule_days, trail_to_first_class, class_costs)
  input_table = CSV.read(input_file)
  input_table_len = input_table.length()

  # STDOUT.puts "START input table: Length is #{input_table.length()}"
  # lineNo = 0
  # input_table.each do |table_line|
  #   STDOUT.puts "Line #{lineNo}: #{table_line}" 
  #   lineNo += 1
  # end
  # STDOUT.puts "END   input table"

  if input_table[1].join(",") != schedule_days
    STDOUT.puts "Error in #{input_file}: Unknown schedule days: #{input_table[1].join(",")}"
    return
  end
  
  name_blag = input_table[0][0].split(' ')
  kid_name = "\"#{name_blag[0]} #{name_blag[1][0,1]}\""
  sort = "\"#{name_blag[1]}_#{name_blag[0]}\""
  
  the_slot = 2

  session_1 = ['', '']
  session_2 = ['', '']
  session_3 = ['', '']
  session_4 = ['', '']

  firstYear = false

  input_table[the_slot..-1].each do |input_table_slot|
    if ["08:00 AM", "08:30 AM"].include? input_table_slot[0]
      session_1 = parse_time_slot("08:30 AM", input_table_slot, session_1)
      firstYear = firstYear || (session_1[0] == trail_to_first_class)
    end
  
    if ["09:30 AM", "10:00 AM"].include? input_table_slot[0]
      session_2 = parse_time_slot("09:30 AM", input_table_slot, session_2)
      firstYear = firstYear || (session_2[0] == trail_to_first_class)
    end

    if ["02:00 PM"].include? input_table_slot[0]
      session_3 = parse_time_slot("02:00 PM", input_table_slot, session_3)
      firstYear = firstYear || (session_3[0] == trail_to_first_class)
    end

    if ["03:00 PM", "03:30 PM"].include? input_table_slot[0]
      session_4 = parse_time_slot("03:00 PM", input_table_slot, session_4)
      firstYear = firstYear || (session_4[0] == trail_to_first_class)
    end
  end

  if firstYear
    sort = sort[0] + "1_" + sort[1..]
  end

  cost = add_costs(session_1, class_costs) + add_costs(session_2, class_costs) + add_costs(session_3, class_costs) + add_costs(session_4, class_costs)

  if session_1.join("") != "" || session_2.join("") != "" || session_3.join("") != "" || session_4.join("") != ""
    output_file.puts "#{kid_name},#{sort},\"#{session_output(session_1)}\",\"#{session_output(session_2)}\",\"#{session_output(session_3)}\",\"#{session_output(session_4)}\",$#{cost}"
  end

end

check_params class_costs_file

input_folder = ENV["CAMPER_SCHEDULES"]
output_folder = ENV["OUTPUT_FOLDER"]
current_date = DateTime.now.strftime "%Y-%m-%d_%H-%M-%S"

class_costs_file_data = File.read(class_costs_file)
class_costs = JSON.parse(class_costs_file_data)

abort("Look at the leaders' guide and figure out the right days for merit badges\nAKA where does family day fall?")
open("#{output_folder}/tote-board_#{current_date}.csv", 'w+') do |file|

  # TODO make sure the dates are right here.
  file.puts ',,"Day 2-4 / 5-8",,,,,Notes /'
  file.puts 'Name,SORT,8:30,9:30,2:00,3:00,Costs,Rank Advancement'

  Dir["#{input_folder}/*.csv"].each do |input_file|

    STDOUT.puts "File: #{File.basename(input_file)}"
    parse_input_file input_file, file, schedule_days, trail_to_first_class, class_costs
  
  end     # Dir[input_folder].each do |input_file|

end       # open("outputs/tote-board_#{current_date}.csv", 'w+') do |file|