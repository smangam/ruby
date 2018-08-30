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
$stdout = File.open("/root/smangam/apg_health_report.txt","w")
puts "Subject: APG Health Report"
puts " "
puts "APG Heatlh Report"
#Didatacommon.apg_service_status_all
Didatacommon.backend_tmpdir_status_all
Didatacommon.apg_cdm_failover_filter_status_all
$stdout.close
$stdout=old_stdout
cmd="cat /root/smangam/apg_health_report.txt|wc -l"
output=`#{cmd}`.chomp
if output.chomp.to_i > 4
  Didatacommon.email_report("/root/smangam/apg_health_report.txt")
end
