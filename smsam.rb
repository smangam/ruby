#!/usr/bin/ruby
##################################################
# author: sunil mangam
# menu driven interface for SAM
##################################################

def myMenu
 puts "Choose an option:
 1 Search events by string
 2 Archive an event by string
 3 Archive an event by index
 4 Archive an event by index range
 5 Retrieve a file from CDM
 9 Exit"
 case gets.strip
 when "1"
   cdm = "amcdlsam01"
   puts "Enter event search string: "
   inputstr = gets.chomp
   cmd="ssh root@"+cdm+ " dmctl -s AMCDL_SAM9990 geti ICIM_Notification|grep -e " + """'""" + inputstr + """'""" + " | awk '{print $1}'"
   output=`#{cmd}`
   $events_arr = output.split(/\n/)
   puts "Index   Notification"
   $events_arr.each do |n|
     puts "(#{$events_arr.index(n).to_s})  #{n}"
   end 
   #puts "\nDo you want to apply another filter? (y/n)"
   #if gets.chomp == "y"
   #  puts "Enter the string"
   #  mystr = gets.chomp
   #  mytemp = $events_arr.grep(/#{mystr}/)
   #  puts mytemp
   #end
 when "2"
   cdm = "amcdlsam01"
   puts "Enter the notification that you would like to archive:"
   inputstr = gets.chomp
   notif = "'"+inputstr+"'"
   puts "Archiving notification:"+ notif
   cmd = "ssh root@"+cdm+ " dmctl -s AMCDL_SAM9990 delete ICS_Notification::"+inputstr
   output=`#{cmd}` 
   puts output
 when "3"
   cdm = "amcdlsam01"
   puts "Enter the notification index you would like to archive:"
   n = gets.chomp.to_i
   notif = "'"+$events_arr[n]+"'"
   puts "Archiving notification:"+ notif
   cmd = "ssh root@"+cdm+ " dmctl -s AMCDL_SAM9990 delete ICS_Notification::"+notif
   output=`#{cmd}` 
   puts output
 when "4"
   cdm = "amcdlsam01"
   puts "Enter the notification begin index you would like to archive:"
   n = gets.chomp.to_i
   puts "Enter the notification end index you would like to archive:"
   m = gets.chomp.to_i
   $events_arr[n,m].each do |myevent|
     #notif = "'"+myevent+"'"
     puts "Archiving notification:"+ myevent
     cmd = "ssh root@"+cdm+ " dmctl -s AMCDL_SAM9990 delete ICS_Notification::"+myevent
     output=`#{cmd}` 
     puts output
   end
 when "9"
  exit
 else
  puts "else"
 end
end

while true
 myMenu()
end
