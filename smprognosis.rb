#!/usr/bin/ruby

require '/root/smangam/didatacommon'

$menu=0

def get_classes
   cmd = "ssh root@"+$cdm +" dmctl -s "+ $APMserver + " getc"
   output=`#{cmd}`
   puts output
end

def get_instance_properties_sysobjectid
   print "enter the instance:"
   value = gets.chomp
   cmd = "ssh root@"+$cdm +" dmctl -s "+ $APMserver + " get  ICIM_UnitaryComputerSystem::#{value}::SystemObjectID"
   $sysobjectid=`#{cmd}`
   puts $sysobjectid
end

def find_certification_by_sysobjectid
  print "enter device sysobjectid:"
  $sysobjectid=gets.chomp
  certdir=["/opt/InCharge9/IP/smarts/regional/conf/discovery/oid2type_Field.conf","/opt/InCharge9/IP/smarts/conf/discovery/oid*conf"]
  File.open("/root/smangam/cdm_solo.txt").each { |x|
    mycdm=x.chomp
    certdir.each { |mydir|
      cmd="ssh root@#{mycdm} grep #{$sysobjectid} #{mydir}"
      if system("#{cmd}")
        cmd="ssh root@#{mycdm} grep -l #{$sysobjectid} #{mydir}"
        output=`#{cmd}`
        puts output
      end
    }
  }
end

def find_certification_by_model
  print "enter device model or sysobjectid:"
  model=gets.chomp
  certdir=["/opt/InCharge9/IP/smarts/regional/conf/discovery/oid2type_Field.conf","/opt/InCharge9/IP/smarts/conf/discovery/oid*conf"]
  certdir.each { |mydir|
    cmd="ssh root@#{$cdm} grep #{model} #{mydir}"
    if system("#{cmd}")
      cmd="ssh root@#{$cdm} grep -l #{model} #{mydir}"
      output=`#{cmd}`
      puts output
    end
  }
end

def find_certification_by_model_all
  print "enter device model or sysobjectid:"
  model=gets.chomp
  certdir=["/opt/InCharge9/IP/smarts/regional/conf/discovery/oid2type_Field.conf","/opt/InCharge9/IP/smarts/conf/discovery/oid*conf"]
  File.open("/root/smangam/cdm_solo.txt").each { |x|
    mycdm=x.chomp
    certdir.each { |mydir|
      cmd="ssh root@#{mycdm} grep #{model} #{mydir}"
      if system("#{cmd}")
        cmd="ssh root@#{mycdm} grep -l #{model} #{mydir}"
        output=`#{cmd}`
        puts "#{mycdm} #{output}"
      end
    }
  }
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
 Device Information
   1: list Prognosis Server for #{$cdm}
   2: list devices by type (Switch,Router,Firewall,Host,Node)
   3: list important properties of a device
   4: show device certification for a given sysobjectid
 Instrumentation for a Device
   10: list of instrumentation objects for a given device (#{$device})
   11: list details of a given instrumentation object
 Instrumentation for a Device used by APG
   20: select instrumentation classes from the list
   21: list of instrumentation objects for a given device for class #{$apg_instrumentation_class}
   22: instrumentation object details for a given device for class #{$apg_instrumentation_class}
 DEVICE OIDINFO
   30: get OID info for a device
   31: show OID info for a given instrumentation class (#{$instrumentation_class})
   32: show OID info file
 EXIT Program
   9: Exit"
  case gets.strip
  when "0"
    Didatacommon.get_cdm
  when "1"
    Didatacommon.prog_server_for_cdm
  when "2"
    Didatacommon.get_instances_apm
  when "3"
    Didatacommon.get_instance_properties_apm
  when "4"
    Didatacommon.show_certification_apm
  when "10"
    Didatacommon.apm_get_device_instrumentation_objects
  when "11"
    Didatacommon.apm_get_instrumentation_object_details
  when "20"
    Didatacommon.apm_instrumentation_classes_used_by_apg
  when "21"
    Didatacommon.apm_get_device_instrumentation_objects_for_class
  when "22"
    Didatacommon.apm_get_instrumentation_object_details_for_class
  when "30"
    Didatacommon.apm_device_oidinfo
  when "31"
    Didatacommon.apm_show_oidinfo_file_with_filter
  when "32"
    Didatacommon.apm_show_oidinfo_file
  when "9"
    $menu=1
    puts "exiting..."
    exit
  end
end

while $menu==0
  if $cdm != nil
    puts "CDM is #{$cdm}"
  else
   Didatacommon.get_cdm 
  end
  mainmenu
end

