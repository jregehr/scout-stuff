#!/usr/bin/env ruby

######################################################################################
# This script will read a unit progress export file and build a scoutbook CSV.       #
######################################################################################

require 'date'
require 'csv'

MB_REGEX = %r{LS ([A-z\.\/2& ]+) [0-9:]+ [0-9 A-z]+}

def check_params()
  progress_export_missing = ENV["PROGRESS_EXPORT"].nil? || ENV["PROGRESS_EXPORT"].empty?
  key_file_missing = ENV["KEY_FILE"].nil? || ENV["KEY_FILE"].empty?
  output_folder_missing = ENV["OUTPUT_FOLDER"].nil? || ENV["OUTPUT_FOLDER"].empty?
  return if !progress_export_missing && !output_folder_missing && !key_file_missing

  bad_things = ''
  bad_things += "PROGRESS_EXPORT" if progress_export_missing
  bad_things += ", " if progress_export_missing && (output_folder_missing || key_file_missing)
  bad_things += "KEY_FILE" if key_file_missing
  bad_things += ", " if output_folder_missing
  bad_things += "OUTPUT_FOLDER" if output_folder_missing
  abort("Missing parameters: #{bad_things}")
end

def parse_badge_name(badge_name_str)

  matches = badge_name_str.match(MB_REGEX)

  if matches[1] == 'Pottery/Sculpture'
    return [ 'Pottery', 'Sculpture' ]
  end

  if matches[1] == 'Long Range .22'
    return [ 'Long Range .22 Marksmanship' ]
  end

  if matches[1] == 'Snorkeling'
    return [ 'Snorkeling BSA' ]
  end

  return [ matches[1] ]
end

def parse_badge_data(pbd_input_table, pbd_file, pbd_progress_file, pbd_row_number, pbd_camper_name, pbd_bsa_id, pbd_bartle_end_date, pbd_counselor)

  badge_names = parse_badge_name pbd_input_table[pbd_row_number][0]
  
  badge_names.each do |badge_name|
    if badge_name == 'Trail to First Class'
      next
    end
    result = "#{pbd_bsa_id},#{pbd_camper_name},"
    completed = pbd_input_table[pbd_row_number+1][1]
    award_type = 'Merit Badge'
    if [ 'Long Range .22 Marksmanship', 'Snorkeling BSA' ].include? badge_name
      award_type = 'ScoutAward'
    end
    result += "#{award_type},#{badge_name}"
    if completed == "Yes"
      result += ",,#{pbd_bartle_end_date.strftime("%m-%d-%Y")},1,,#{pbd_counselor}\r"
      pbd_file.puts result
    else
      parse_partial_badge_data result, pbd_input_table, pbd_progress_file, pbd_row_number, pbd_bartle_end_date, pbd_counselor
    end
    STDOUT.puts result
  end

  return pbd_row_number + 3

end

def parse_partial_badge_data(ppbd_result_start, ppbd_input_table, ppbd_progress_file, ppbd_row_number, ppbd_bartle_end_date, ppbd_counselor)
  # STDOUT.puts "Parsing partial: #{ppbd_input_table[ppbd_row_number]}"
  # STDOUT.puts "Parsing partial: #{ppbd_input_table[ppbd_row_number+1]}"
  # STDOUT.puts "Resultstart: #{ppbd_result_start}"

  (2..(ppbd_input_table[ppbd_row_number+1].length()-1)).each do |n|
    # STDOUT.puts "Column #{n}"
    if ppbd_input_table[ppbd_row_number+1][n] == nil || ppbd_input_table[ppbd_row_number+1][n] == " "
      next
    end
    if ppbd_input_table[ppbd_row_number+1][n] == 'X'
      # STDOUT.puts "YES"
      real_result = "#{ppbd_result_start.gsub("Merit Badge", "Merit Badge Requirement")}"
      requirement = ppbd_input_table[ppbd_row_number][n].split("-")[0]
      if requirement.length() > 2 && requirement[0] == "1"
        results = Array.new
        results[0] = real_result + "#" + requirement[0..1] + ",,#{ppbd_bartle_end_date.strftime("%m-%d-%Y")},1,,#{ppbd_counselor}\r"
        results[1] = real_result + "#" + requirement[0] + requirement[2] + ",,#{ppbd_bartle_end_date.strftime("%m-%d-%Y")},1,,#{ppbd_counselor}\r"
        ppbd_progress_file.puts results[0]
        ppbd_progress_file.puts results[1]
      else
        real_result += "##{requirement}" #requirement
        real_result += ",,#{ppbd_bartle_end_date.strftime("%m-%d-%Y")},1,,#{ppbd_counselor}\r"
        ppbd_progress_file.puts real_result
      end
    end
  end
end

check_params

input_file = ENV["PROGRESS_EXPORT"]
key_file = ENV["KEY_FILE"]
output_folder = ENV["OUTPUT_FOLDER"]
current_date = DateTime.now.strftime "%Y-%m-%d_%H-%M-%S"

bartle_end_date = DateTime.new(2022, 7, 1)
counselor = "\"H. Roe Bartle Scout Reservation\""
counselor = "H. Roe Bartle Scout Reservation"
counselor = "Bartle"

row_number = 2

bsa_ids = Hash.new
CSV.foreach(key_file, { headers: true }) do  |key_row|
  bsa_ids["#{key_row[0]}, #{key_row[1]}"] = key_row[2]
end

# STDOUT.puts bsa_ids

open("#{output_folder}/Troop_284_advancement_#{current_date}.csv", 'w+') do |file|
  open("#{output_folder}/Troop_284_progress_#{current_date}.csv", 'w+') do |progress_file|

    # file.puts 'BSA Member ID,First Name,Middle Name,Last Name,Advancement Type,Advancement,Version,Date Completed,Approved,Awarded,Counselor'
    file.puts 'BSA Member ID,First Name,Middle Name,Last Name,Advancement Type,Advancement,Version,Date Completed,Approved,Awarded,Counselor'
    progress_file.puts 'BSA Member ID,First Name,Middle Name,Last Name,Advancement Type,Advancement,Version,Date Completed,Approved,Awarded,Counselor'

    input_table = CSV.read(input_file)
    input_table_len = input_table.length()

    STDOUT.puts "input length: #{input_table_len}"
    # STDOUT.puts "2sub0: #{input_table[2][0]}"
    # STDOUT.puts "0sub2: #{input_table[0][2]}"

    camper_name = ""
    bsa_id = ""

    while row_number < input_table_len

      # STDOUT.puts "Row #{row_number}: #{input_table[row_number][0]}"
      
      # Camper name - only data in column 0
      if input_table[row_number][0] != '' && input_table[row_number][1] == nil
        camper_name_arr = input_table[row_number][0].split(',')
        STDOUT.puts "set camper to #{camper_name_arr}"
        camper_name = "\"#{camper_name_arr[1].strip}\",,\"#{camper_name_arr[0].strip}\""
        camper_name = "#{camper_name_arr[1].strip},,#{camper_name_arr[0].strip}"
        bsa_id = bsa_ids[input_table[row_number][0]]
        row_number += 1
        next
      end

      # end of file
      if input_table[row_number][0] == 'X'
        STDOUT.puts "end of file"
        break
      end

      # Completion data 
      row_number = parse_badge_data input_table, file, progress_file, row_number, camper_name, bsa_id, bartle_end_date, counselor
    
    end     # while row_number < input_table_len
  end       # open("#{output_folder}/Troop_284_progress_#{current_date}.csv", 'w+') do |progress_file|
end         # open("#{output_folder}/Troop_284_advancement_#{current_date}.csv", 'w+') do |file|