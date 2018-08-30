#!/usr/bin/ruby
#########################################
# 1. monitor all APG services on portals, databases, backends, and CDMs
# 2. restart stopped services
# 3: monitor qdf backlogs
# 4: manage qdf backlog files
# this script runs for about 10 mins
#########################################

require '/root/smangam/didatacommon2'

old_stdout=$stdout
$stdout = File.open("/root/smangam/apg_services_health_report.txt","w")
puts "Subject: APG Services Health Report"
puts " "
puts "APG Services Heatlh Report"
#Didatacommon.apg_service_status_all
$stdout.close
$stdout=old_stdout
cmd="cat /root/smangam/apg_services_health_report.txt|wc -l"
output=`#{cmd}`.chomp
if output.chomp.to_i > 3
  Didatacommon.email_report("/root/smangam/apg_services_health_report.txt")
end
