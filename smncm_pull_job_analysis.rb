#!/usr/bin/ruby

require '/root/smangam/didatacommon2'

$menu=0

def search_device_byip
  puts "NCM creates a device name using alias, hostname, or fqdn. this order can be changed in NCM app server, System Admin, Global, Device Options, Device Naming Scheme"
  puts "sometimes the device name in ITSM may not match the name in NCM"
  print "enter device ip address:"
  ip=gets.chomp
  ncmappservers=["amcdlncmapp01","amcdlncmapp02","amcdlncmapp03","amcdlncmapp04"]
  ncmappservers.each { |x|
    cmd="grep #{ip} /root/smangam/#{x}_cflist.txt"
    output=`#{cmd}`
    puts output
  }
end

def find_driver_by_sysobjectid
  print "enter device sysobjectid:"
  id=gets.chomp
  cmd="ssh root@#{$cdm} grep -r #{id} /opt/smarts-ncm/*package*/"
  puts `#{cmd}`
end

def find_driver_by_sysobjectid_all
  print "enter device sysobjectid:"
  sysobjectid=gets.chomp
  File.open("/root/smangam/cdm_solo.txt").each { |x|
    mycdm=x.chomp
    cmd="ssh root@#{$cdm} grep -r #{sysobjectid} /opt/smarts-ncm/*package*/"
    if system("#{cmd}")
      cmd="ssh root@#{mycdm} grep -rl #{$sysobjectid} /opt/smarts-ncm/*package*/"
      puts "#{mycdm} " + `#{cmd}`
    end
   }
end

def select_driver_based_on_snmp
  print "A device driver is selected for a given device usihg SNMP as follows:"
  print "Each of the model.xml files in /opt/smarts-ncm/custompackage/pkgxml is searched for a matching entry for the device's sysobjectid (example, /opt/smarts-ncm/custompackage/pkgxml/CiscoCustom_CiscoIOS_DDAM/CiscoCustom_CiscoIOS_DDAMModels.xml)"
  print "In autodisc.log file, the SNMP search begins with ------ SNMP Discovery Order"
end

=begin
print "enter the task id for the pull request:"
task_id=gets.chomp
puts "May 22 20:00:26 2071979776/30#1: <Perf> Found a new command, cmdStr=pull minpri=0 maxpri=30 taskId=986ef21ffb9dd43f472c708963010000#4956797"
puts "
May 22 20:00:26 2071979776/30#1: ++++++ Manager 0 30 Sub-thread pull,21832,986ef21ffb9dd43f472c708963010000#4956797 - 986ef21ffb9dd43f472c708963010000#4956797 #2030016256 created @ priority 25
May 22 20:00:26 2030016256/pull(4956797)#1: Sent Notify:TASK_STATUS IDX(21832) TASK(986ef21ffb9dd43f472c708963010000#4956797) network(986ef21e5c26e63f4077868840010000) user(c21hbmdhbQ==) status(Task started on AM-TXDOT May 22 20:00:26)
May 22 20:00:26 2030016256/pull(4956797)#4: MgrStatus::operStart type(pull) id(986ef21ffb9dd43f472c708963010000#4956797)
May 22 20:00:26 2030016256/pull(4956797)#4: Using Network OID 986ef21e5c26e63f4077868840010000
"
grep for pull(4956797)
=end

def mainmenu
 puts "select an option
   0: enter CDM
 Device Information from APM
   1: search for a device in APM
   2: list important properties of a given device from APM
 Device Information
   10: get device information for #{$cdm} from controldb
   11: most recent job id for a given device
   12: most recent job results for a given device
   12a: most recent job results for all devices for #{$cdm}
   13: most recent job task result details for a given device
   13a: most recent config pull status for all devices for #{$cdm}
   13b: most recent config pull failed jobs for all devices for #{$cdm}
   14: print task result details for a given task
 Job Information per CDM from ControlDB
   20: print job summary (total success/failed) for #{$cdm} from controldb
   21: print list of running/completed/failed job names for #{$cdm} from controldb
   22: print running jobs for #{$cdm} from controldb
   23: print running tasks for #{$cdm} from controldb
   24: cancel running tasks for #{$cdm} from controldb
   25: most recent #{$CDM} Weekly Config Pull job executed
   26: print most recent failed running/startup tasks for #{$cdm}
   27: print most recent failed running/startup tasks for #{$cdm} with specific reasons
 Job Report
   40: execute NCM jobs report
 EXIT Program
   99: Exit"
  case gets.strip
  when "0"
    Didatacommon.get_cdm
  when "1"
    Didatacommon.search_instances_apm
  when "2"
    Didatacommon.get_instance_properties_apm
  when "10"
    Didatacommon.get_device_list_from_controldb
  when "11"
    Didatacommon.get_job_status_for_device_from_controldb
  when "12"
    Didatacommon.most_recent_pull_details_for_device
  when "12a"
    Didatacommon.most_recent_pull_details_for_all_devices
  when "13"
    Didatacommon.get_job_results_per_device_from_controldb
  when "13a"
    Didatacommon.list_config_status_for_all_devices
  when "13b"
    Didatacommon.list_config_failed_for_all_devices
  when "14"
    Didatacommon.get_job_result_for_device_from_controldb
  when "20"
    Didatacommon.get_job_status_from_controldb
  when "21"
    Didatacommon.get_jobs_from_controldb
  when "22"
    Didatacommon.get_running_jobs_from_controldb
  when "23"
    Didatacommon.get_running_tasks_from_controldb
  when "24"
    Didatacommon.cancel_running_tasks_from_controldb
  when "25"
    Didatacommon.get_job_status2_from_controldb
  when "26"
    Didatacommon.list_failed_tasks_per_cdm
  when "27"
    Didatacommon.list_failed_tasks_sshkeys_mismatch_per_cdm
  when "40"
    Didatacommon.ncm_run_config_download_report
  when "99"
    $menu=1
    puts "exiting..."
    exit
  end
end

while $menu==0
  if $cdm != nil
    puts "CDM is #{$cdm}. CDM type is #{$cdm_type}"
  else
   Didatacommon.get_cdm
  end
  mainmenu
end
