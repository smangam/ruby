#!/usr/bin/ruby
#########################################
# 1. monitor all APG services on portals, databases, backends, and CDMs
# 2. restart stopped services
# 3: monitor qdf backlogs
# 4: manage qdf backlog files
# this script runs for about 30 mins
#########################################

require '/root/smangam/didatacommon2'

old_stdout=$stdout
$stdout = File.open("/root/smangam/os_health_report.txt","w")
puts "Subject: OS Health Report"
puts " "
puts "OS Health Report"
Didatacommon.fs_status_all
#Didatacommon.fs_cleanup_all
$stdout.close
$stdout=old_stdout
cmd="cat /root/smangam/os_health_report.txt|wc -l"
output=`#{cmd}`.chomp

if output.to_i >4
  Didatacommon.email_report("/root/smangam/os_health_report.txt")
end
