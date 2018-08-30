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
$stdout = File.open("/root/smangam/ncm_health_failed_jobs_report.txt","w")
puts "Subject: NCM Failed Jobs Report"
puts " "
puts "NCM Failed Jobs Report"
Didatacommon.list_config_failed_for_all_devices_report
$stdout.close
$stdout=old_stdout
cmd="cat /root/smangam/ncm_health_failed_jobs_report.txt|wc -l"
output=`#{cmd}`.chomp

if output.to_i >3
  Didatacommon.email_report("/root/smangam/ncm_health_failed_jobs_report.txt")
end
