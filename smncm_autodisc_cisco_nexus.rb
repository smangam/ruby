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
 DEVICE Information from InfraDB
   3: list all device data from NCM Infra database for #{$cdm}
   4: get specific device data from NCM Infra database on #{$ncm_appserver}
   5: list devices by sysobjectid in Infra database from all CDMs
   6: get device server for a given POP I
 DEVICE Information from ControlDB
   7: get device information for #{$cdm} from controldb
 DEVICE DISCOVERY - Ping and SNMPWALK Test 
   10: test ping,snmpwalk,telnet,ssh on a device
   11: device contract information in ITSM
 DEVICE DISCOVERY Logs
   20: autodiscovery logs for a given device
   21: get complete autodiscovery logs
   22: restart autodiscd process
   23: set log levels for autodiscovery
 DEVICE DISCOVERY
   31: was the device discovered under a different name?
   32: is the device sysobjectid supported by any driver?
   33: is the device sysobjectid supported by any driver in other CDMs?
 DEVICE DISCOVERY - List of Device Drivers
   40: is the right device driver in the managed device driver list in the NCM app server?
   41: list of cisco device drivers
 Device Discovery Using the Driver - Cisco Nexus_DDAM (30911)
   50: get /opt/smarts-ncm/custompackage/pkgxml/CiscoNexus_DDAM/CiscoNexus_DDAMModels.xml file from #{$cdm}
   51: check if sysobjectid exists in the CiscoNexus_DDAMModels.xml file
   51: manually edit in the local copy of CiscoNexus_DDAMModels.xml file
   53: push CiscoNexus_DDAMModels.xml file to #{$cdm}
 EXIT Program
   9: Exit"
  case gets.strip
  when "0"
    Didatacommon.get_cdm
  when "1"
    Didatacommon.search_instances_apm
  when "2"
    Didatacommon.get_instance_properties_apm
  when "3"
    Didatacommon.list_devices_for_ds_infradb
  when "4"
    Didatacommon.get_device_from_infradb
  when "5"
    Didatacommon.find_devices_in_infradb
  when "6"
    Didatacommon.ncm_get_ds_for_popid_infradb
  when "7"
    Didatacommon.get_device_list_from_controldb
  when "10"
    Didatacommon.test_ping
    print "enter snmp version(v2,v3):"
    version=gets.chomp
    if version == 'v3'
      Didatacommon.test_snmpv3
    else
      Didatacommon.test_snmpv2
    end
    print "enter device ip address:"
    ip=gets.chomp
    cmd="ssh root@#{$cdm} telnet #{ip}"
    puts `#{cmd}`
    puts "please login to the cdm and test ssh connection"
  when "11"
    Didatacommon.ncm_itsm_device_contract
  when "20"
    Didatacommon.ncm_autodisclogs
  when "21"
    Didatacommon.ncm_autodisclogs_full
  when "31"
    search_device_byip
  when "32"
    find_driver_by_sysobjectid
  when "33"
    find_driver_by_sysobjectid_all
  when "40"
    Didatacommon.ncm_packageorder
  when "41"
    Didatacommon.ncm_packageorder_cisco
  when "50"
    Didatacommon.ncm_custompackage_cisco_modelsfile
  when "51"
    Didatacommon.ncm_update_cisco_modelsfile
  when "52"
    Didatacommon.ncm_generate_ciscomodels_xml_file
  when "53"
    Didatacommon.ncm_push_ciscomodels_file
  when "9"
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
