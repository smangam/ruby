#!/usr/bin/ruby
###################################################
# author: sunil mangam
# get overall OS status on a host
###################################################

puts "Enter host:"
hostname = gets.chomp

def mymenu(hostname)
 cmd_pre="ssh root@"+hostname
 puts "Choose an option:
 1 print memory status
 2 print disk usage
 3 print top with highest %CPU usage
 4 print top with highest MEM usage
 5 print top for sm_server
 6 print top for apg
 9 Exit"
 case gets.strip
 when "1"
  cmd=cmd_pre+" free -m"
  puts "mem usage \n"+`#{cmd}`
  cmd=cmd_pre+" cat /proc/swaps"
  puts "\nswapinfo for #{hostname}\n"+`#{cmd}`
 when "2"
  cmd=cmd_pre+" df -h"
  puts "disk info for #{hostname}\n"+ `#{cmd}`
 when "3"
  cmd=cmd_pre+"  top -b -o %CPU -n 1|head -n 20"
  puts "top for CPU for #{hostname}\n"+ `#{cmd}`
 when "4"
  cmd=cmd_pre+"  top -b -o RES -n 1|head -n 20"
  puts "top for MEM\n"+ `#{cmd}`
 when "5"
  cmd=cmd_pre+"  top -b -n 1|grep sm_server"
  puts "top for MEM\n"+ `#{cmd}`
 when "6"
  cmd=cmd_pre+"  top -b -n 1| grep apg"
  puts "top for MEM\n"+ `#{cmd}`
 when "9"
  exit
 end
end

while true
 mymenu(hostname)
end
