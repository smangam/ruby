#!/usr/bin/ruby

require '/root/smangam/didatacommon2'
$menu=0

def get_instances
   print "enter the class name:"
   value = gets.chomp
   cmd = "ssh root@"+$cdm +" dmctl -s "+ $APMserver + " geti #{value}"
   output=`#{cmd}`
   puts output
end

def get_interface_instances
   cmd = "ssh root@"+$cdm +" dmctl -s "+ $APMserver + " geti ICIM_NetworkAdapter"
   output=`#{cmd}`
   puts output
end

def get_instance_property_instrumentedby
   puts "common classes: Router,Switch, ICIM_NetworkAdapter, UnitaryComputerSystem"
   print "enter the instance (as <class>:<instance>):"
   value = gets.chomp
   cmd = "ssh root@"+$cdm +" dmctl -s "+ $APMserver + " get  ICIM_UnitaryComputerSystem::#{value}::InstrumentedBy"
   output=`#{cmd}`
   puts output
end

def get_interface_property_instrumentedby
   puts "common classes: Router,Switch, ICIM_NetworkAdapter, UnitaryComputerSystem"
   print "enter the instance (as <class>:<instance>):"
   value = gets.chomp
   cmd = "ssh root@"+$cdm +" dmctl -s "+ $APMserver + " get  ICIM_NetworkAdapter::#{value}::InstrumentedBy"
   output=`#{cmd}`
   puts output
end

def get_size
  cmd = "ssh root@"+$cdm + " /opt/In*/IP/smarts/bin/sm_tpmgr -s #{$APMserver} --size"
end

def enable_debug
   puts "DebugEnabled setting is:"
   cmd = "ssh root@"+$cdm +" dmctl -s "+ $APMserver + " get ICF_TopologyManager::ICF-TopologyManager::DebugEnabled"
   output=`#{cmd}`
   puts output
   print "Set DebugEnabed to TRUE/FALSE:"
   value=gets.chomp
   cmd = "ssh root@"+$cdm+ " dmctl -s "+ $APMserver + " put ICF_TopologyManager::ICF-TopologyManager::DebugEnabled "+value
   puts cmd
end

def enable_SNMP_accessor_dump
   print "enter instance name:"
   value=gets.chomp
   #cmd = "ssh root@"+$cdm +" dmctl -s "+ $APMserver + " get ICIP_SNMPAccessorInterface::DEVSTAT-SNMP-Poller::"
   cmd = "ssh root@"+$cdm +" dmctl -s "+ $APMserver + " invoke ICIP_SNMPAccessorInterface::DEVSTAT-SNMP-Poller setTrace ICIM_UnitaryComputerSystem::#{value} TRUE"
   puts cmd
   output=`#{cmd}`
   puts output
end

def disable_SNMP_accessor_dump
   print "enter instance name:"
   value=gets.chomp
   cmd = "ssh root@"+$cdm +" dmctl -s "+ $APMserver + " invoke ICIP_SNMPAccessorInterface::DEVSTAT-SNMP-Poller setTrace ICIM_UnitaryComputerSystem::#{value} FALSE"
   puts cmd
   output=`#{cmd}`
   puts output
end

def list_agents
   cmd = "ssh root@"+$cdm +" /opt/InCharge9/IP/smarts/bin/sm_tpmgr -s  "+ $APMserver + " --show-agent-state"
   puts cmd
   output=`#{cmd}`
   puts output
end

def search_agents
   print "enter device search string:"
   device=gets.chomp
   cmd = "ssh root@"+$cdm +" /opt/InCharge9/IP/smarts/bin/sm_tpmgr -s  "+ $APMserver + " --show-agent-state | grep #{device}"
   output=`#{cmd}`
   puts output
end

def mainmenu
 puts "select an option
   0: enter CDM
 DEVICE Information
   1: search for an device
   2: list devices by type (Switch,Router,Firewall,Host,Node)
   3: list properties of an device (specify device)
   4: test if ping works to the device
   5: test if snmp v2 works to the device
   6: test if snmp v3 works to the device
 Check If Certification Exists
   20: check if certification exists for a sysobjectid in #{$cdm}
   21: check if certification exists for a sysobjectid in all CDMs
 DEVICE CERTIFICATION
   31: find matching certification in #{$cdm} using device model or sysobjectid
   32: find matching certification in other CDMs using device model or sysobjectid (all CDMs)
   33: show certification
   34: pull custom certification file for #{$cdm}
   35: create certification stanza
   36: copy certification stanza to the custom certification file
   37: validate custom certification file
   38: push custom certification file for #{$cdm}
   39: Reload OID files (after adding device certification)
 DEVICE DISCOVERY
   40: Rediscover a device discovered as node
   41: Rediscover all devices of a given device type
 EXIT Program
   9: Exit"
  case gets.strip
  when "0"
    Didatacommon.get_cdm
  when "1"
   Didatacommon.search_instances_apm
  when "2"
    Didatacommon.get_instances_apm
  when "3"
    Didatacommon.get_instance_properties_apm
  when "4"
    Didatacommon.test_ping
  when "5"
    Didatacommon.test_snmpv2
  when "6"
    Didatacommon.test_snmpv3
  when "20"
    Didatacommon.apm_find_certification_for_sysobjectid_in_cdm
  when "21"
    Didatacommon.apm_find_certification_for_sysobjectid_in_all
  when "31"
    Didatacommon.find_certification_by_model_apm
  when "32"
    Didatacommon.find_certification_by_model_all_apm
  when "33"
    Didatacommon.show_certification_apm
  when "34"
    Didatacommon.pull_custom_oidfile_apm
  when "35"
    Didatacommon.create_stanza_apm
  when "36"
    Didatacommon.append_stanza_apm
  when "37"
   Didatacommon.validate_custom_oidfile_apm
  when "38"
    Didatacommon.push_custom_oidfile_apm
  when "39"
    Didatacommon.reload_oid_apm
  when "40"
    Didatacommon.device_discovery_apm
  when "41"
    Didatacommon.device_discovery_apm_all_device_types
  when "9"
    $menu=1
    puts "exiting..."
    exit
  end
end

while $menu==0
  if $cdm != nil
    puts "CDM is #{$cdm}"
    puts "device is #{$device}"
  else
   Didatacommon.get_cdm 
  end
  mainmenu
end

