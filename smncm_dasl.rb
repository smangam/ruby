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


def mainmenu
 puts "select an option
   0: enter CDM
 DEVICE Information from APM
   1: search for a device in APM
   2: list important properties of a given device from APM
   3: list of CDMs that exist in APM but dont exist in NCM
   3a: list of CDMs with no device backup data
 DEVICE Information from InfraDB
   4: list all device data from NCM Infra database for #{$cdm}
   5: get specific device data from NCM Infra database on #{$ncm_appserver}
   6: list devices by sysobjectid in Infra database from all CDMs
   7: get device server for a given POP ID
 DEVICE Information from ControlDB
   10: get device information for #{$cdm} from controldb
   11: most recent job id for a given device
   12: most recent job results for a given device
   13: device status(unclassified,operational,etc) report for #{$cdm}
   14: device status(unclassified,operational,etc) report for all networks
   15: device status by category(unclassified,operational,etc) for all networks
 Execute DASL
   20: execute dasl script
 EXIT Program
   99: Exit"
  case gets.strip
  when "0"
    Didatacommon.get_cdm
  when "1"
    Didatacommon.search_instances_apm
  when "2"
    Didatacommon.get_instance_properties_apm
  when "3"
    Didatacommon.ncm_list_cdms_not_in_ncm
  when "3a"
    Didatacommon.ncm_list_cdms_with_no_jobs
  when "4"
    Didatacommon.list_devices_for_ds_infradb
  when "5"
    Didatacommon.get_device_from_infradb
  when "6"
    Didatacommon.find_devices_in_infradb
  when "7"
    Didatacommon.ncm_get_ds_for_popid_infradb
  when "8"
    Didatacommon.list_duplicate_device_names_in_infradb_cdm
  when "9"
    Didatacommon.list_duplicate_device_names_in_infradb_all
  when "10"
    Didatacommon.get_device_list_from_controldb
  when "11"
    Didatacommon.get_job_status_for_device_from_controldb
  when "12"
    Didatacommon.most_recent_pull_details_for_device
  when "13"
    Didatacommon.ncm_device_status_per_cdm_controldb
  when "14"
    Didatacommon.ncm_device_status_all_controldb
  when "15"
    Didatacommon.ncm_unclassified_devices_all_controldb
  when "20"
    Didatacommon.ncm_execute_dasl
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
