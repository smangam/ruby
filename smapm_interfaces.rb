#!/usr/bin/ruby

require '/root/smangam/didatacommon'
$menu=0

def get_instance_properties_sysobjectid
   print "enter the instance:"
   value = gets.chomp
   cmd = "ssh root@"+$cdm +" dmctl -s "+ $APMserver + " get  ICIM_UnitaryComputerSystem::#{value}::SystemObjectID"
   $sysobjectid=`#{cmd}`
   puts $sysobjectid
end

def find_certification
  print "enter device sysobjectid:"
  $sysobjectid=gets.chomp
  certdir=["/opt/InCharge9/IP/smarts/regional/conf/discovery/oid2type_Field.conf","/opt/InCharge9/IP/smarts/conf/discovery/oid*conf"]
  certdir.each { |mydir|
    cmd="ssh root@#{$cdm} grep #{$sysobjectid} #{mydir}"
    puts cmd
    if system("#{cmd}")
      cmd="ssh root@#{$cdm} grep -A10 #{$sysobjectid} #{mydir}"
      output=`#{cmd}`
      puts output
    end
  }
end

def get_instance_property_instrumentedby
   puts "common classes: Router,Switch, ICIM_NetworkAdapter, UnitaryComputerSystem"
   print "enter the instance:"
   value = gets.chomp
   cmd = "ssh root@"+$cdm +" dmctl -s "+ $APMserver + " get  ICIM_UnitaryComputerSystem::#{value}::InstrumentedBy"
   output=`#{cmd}`
   puts output
end

def get_interface_property_instrumentedby
   puts "common classes: Router,Switch, ICIM_NetworkAdapter, UnitaryComputerSystem"
   print "enter the instance:"
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

def discovery_status
   cmd = "ssh root@"+$cdm +" /opt/InCharge9/IP/smarts/bin/sm_tpmgr -s  "+ $APMserver + " --status"
   puts cmd
   output=`#{cmd}`
   puts output
end

def discovery_pending_list
   cmd = "ssh root@"+$cdm +" /opt/InCharge9/IP/smarts/bin/sm_tpmgr -s  "+ $APMserver + " --pending"
   puts cmd
   output=`#{cmd}`
   puts output
end

def discovery_add_device_snmpv2
   print "enter device ip address:"
   ip_add = gets.chomp
   print "enter SNMP v2c community string:"
   comm_str = gets.chomp
   cmd = "ssh root@"+$cdm +" /opt/InCharge9/IP/smarts/bin/sm_tpmgr -s  "+ $APMserver + " --snmp=2c --community=#{comm_str} --add-agent=#{ip_add} "
   puts cmd
   output=`#{cmd}`
   puts output
end

def discover_pending
   cmd = "ssh root@"+$cdm +" /opt/InCharge9/IP/smarts/bin/sm_tpmgr -s  "+ $APMserver + " --discover-pending"
   puts cmd
   output=`#{cmd}`
   puts output
end

def mainmenu
 puts "select an option
   0: enter CDM
 DEVICE Information
   1: enter device
   2: search for a device
   3: list all classes
   4: list instances for a given class (you should enter the class)
   5: list select properties for the given device #{$device}
   6: list all properties for the given device #{$device}
 INTERFACE/PORT Information
   10: list interface ifdescr/ifadmin/ifoper for device #{$device}  using smnpwalk
   11: list interfaces for device #{$device} from APM
   12: list properties of an interface (specify interface)
   13: list properties for all interfaces for device #{$device} (IsManaged, DisplayName, Description)
   14: list InstrumentedBy property of an interface (specify instance)
   17: steps to configure bandwidth threshold on interfaces
   18: pull /opt/InCharge9/IP/smarts/regional/conf/discovery/RIM_ForcedMaxSpeed.conf for #{$cdm}
   19: push /opt/InCharge9/IP/smarts/regional/conf/discovery/RIM_ForcedMaxSpeed.conf to #{$cdm}
 EXIT Program
   9: Exit"
  case gets.strip
  when "0"
    Didatacommon.get_cdm
  when "1"
    Didatacommon.get_instance_properties_apm
  when "2"
    Didatacommon.search_instances_apm
  when "3"
    Didatacommon.get_classes_apm
  when "4"
    Didatacommon.get_instances_apm
  when "5"
    Didatacommon.get_instance_properties_apm
  when "6"
    Didatacommon.get_instance_properties_all_apm
  when "10"
    Didatacommon.if_snmp_apm
  when "11"
    Didatacommon.get_interface_instances_apm
  when "12"
    Didatacommon.apm_get_interface_properties
  when "13"
    Didatacommon.apm_get_interface_properties_for_all
  when "17"
    Didatacommon.apm_maxspeed_help
  when "18"
    Didatacommon.apm_get_maxspeed_file
  when "19"
    Didatacommon.apm_put_maxspeed_file
  when "9"
    $menu=1
    puts "exiting..."
    exit
  end
end

while $menu==0
  mainmenu
  if $cdm != nil
    puts "CDM is #{$cdm}"
  else
   get_cdm 
  end
end

