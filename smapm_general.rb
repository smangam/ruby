#!/usr/bin/ruby

require '/root/smangam/didatacommon2'
$menu=0

def get_classes
   cmd = "ssh root@"+$cdm +" dmctl -s "+ $APMserver + " getc"
   output=`#{cmd}`
   puts output
end

def get_instances
   print "enter the class name:"
   value = gets.chomp
   cmd = "ssh root@"+$cdm +" dmctl -s "+ $APMserver + " geti #{value}"
   output=`#{cmd}`
   puts output
end

def search_instances
   print "enter the instance search string (use ^,$ to anchor):"
   value = gets.chomp
   cmd = "ssh root@"+$cdm +" dmctl -s "+ $APMserver + " geti |grep #{value}"
   output=`#{cmd}`
   puts output
end

def get_interface_instances
   print "enter search string:"
   mystr = gets.chomp
   cmd = "ssh root@"+$cdm +" dmctl -s "+ $APMserver + " geti ICIM_NetworkAdapter |grep #{mystr}"
   puts cmd
   output=`#{cmd}`
   puts output
end

def get_instance_properties
   puts "common classes: Router,Switch, ICIM_NetworkAdapter, UnitaryComputerSystem"
   puts "use ICIM_UnitaryComputerSystem to cover all classes"
   print "enter the instance:"
   value = gets.chomp
   cmd = "ssh root@"+$cdm +" dmctl -s "+ $APMserver + " get  ICIM_UnitaryComputerSystem::#{value}"
   output=`#{cmd}`
   puts output
end

def get_instance_properties_selected
   print "enter the instance:"
   value = gets.chomp
   properties=["Name","Description","Model","SystemObjectID"]
   cmd = "ssh root@"+$cdm +" dmctl -s "+ $APMserver + " get  ICIM_UnitaryComputerSystem::#{value}::Name"
   $name=`#{cmd}`
   print "Name: "+ $name
   cmd = "ssh root@"+$cdm +" dmctl -s "+ $APMserver + " get  ICIM_UnitaryComputerSystem::#{value}::Description"
   $description=`#{cmd}`
   print "Description: "+ $description
   cmd = "ssh root@"+$cdm +" dmctl -s "+ $APMserver + " get  ICIM_UnitaryComputerSystem::#{value}::SNMPAddress"
   $snmpaddress=`#{cmd}`
   print "SNMPAddress: "+ $snmpaddress
   cmd = "ssh root@"+$cdm +" dmctl -s "+ $APMserver + " get  ICIM_UnitaryComputerSystem::#{value}::Model"
   $model=`#{cmd}`
   print "Model: "+ $model
   cmd = "ssh root@"+$cdm +" dmctl -s "+ $APMserver + " get  ICIM_UnitaryComputerSystem::#{value}::Vendor"
   $vendor=`#{cmd}`
   print "Vendor: "+ $vendor
   cmd = "ssh root@"+$cdm +" dmctl -s "+ $APMserver + " get  ICIM_UnitaryComputerSystem::#{value}::Type"
   $type=`#{cmd}`
   print "Type: "+ $type
   cmd = "ssh root@"+$cdm +" dmctl -s "+ $APMserver + " get  ICIM_UnitaryComputerSystem::#{value}::SystemObjectID"
   $sysobjectid=`#{cmd}`
   print "Sysobjectid: "+ $sysobjectid
   cmd = "ssh root@"+$cdm +" dmctl -s "+ $APMserver + " get  ICIM_UnitaryComputerSystem::#{value}::ReadCommunity"
   $readcommunity=`#{cmd}`
   print "ReadCommunity: "+ $readcommunity
end

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

def get_interface_properties
   puts "common classes: Router,Switch, ICIM_NetworkAdapter, UnitaryComputerSystem"
   puts "use ICIM_UnitaryComputerSystem to cover all classes"
   print "enter the instance:"
   value = gets.chomp
   cmd = "ssh root@"+$cdm +" dmctl -s "+ $APMserver + " get  ICIM_NetworkAdapter::#{value}"
   output=`#{cmd}`
   puts output
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

def reload_oid
   cmd = "ssh root@"+$cdm +" /opt/InCharge9/IP/smarts/bin/sm_tpmgr -s  "+ $APMserver + " --reloadoid"
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

def test_snmpv2
   print "Enter device IP address:"
   ip=gets.chomp
   print "Enter SNMP Community String:"
   community=gets.chomp
   cmd = "ssh root@"+$cdm+ " snmpwalk -v2c -c " + community + " " + ip + " sysobjectid"
   output=`#{cmd}`
   puts output
   cmd = "ssh root@"+$cdm+ " ping -c 3 " + ip
   output=`#{cmd}`
   puts output
end

def test_snmpv3
   print "Enter device IP address:"
   ip=gets.chomp
   print "Enter user name:"
   user=gets.chomp
   print "Enter authentication protocol (SHA or MD5):"
   auth_protocol=gets.chomp
   print "Enter authentication password:"
   auth_password=gets.chomp
   print "Enter authentication level:"
   auth_level=gets.chomp
   print "Enter privilege protocol:"
   priv_protocol=gets.chomp
   print "Enter privilege password:"
   priv_password=gets.chomp

   if priv_protocol == nil
    cmd = "ssh root@#{$cdm} snmpwalk -v3 -u #{user} -a #{auth_protocol} -A #{auth_password}  -l #{auth_level} #{ip} sysobjectid"
   end
   puts #{cmd}
   output=`#{cmd}`
   puts output
   cmd = "ssh root@"+$cdm+ " ping -c 3 " + ip
   output=`#{cmd}`
   puts output
end

def maxspeed_help
 puts "to convert mpbs to bps, multiply by 1000000"
 puts "to convert gbps to bps, multiply by 1000000000"
end

def get_maxspeed_file
  cmd="scp root@#{$cdm}:/opt/InCharge9/IP/smarts/regional/conf/discovery/RIM_ForcedMaxSpeed.conf /root/smangam"
  if system("#{cmd}")
    puts "successfully pulled #{$cdm}:/opt/InCharge9/IP/smarts/regional/conf/discovery/RIM_ForcedMaxSpeed.conf"
  end
end

def put_maxspeed_file
  cmd="ssh root@#{$cdm} cp -p /opt/InCharge9/IP/smarts/regional/conf/discovery/RIM_ForcedMaxSpeed.conf /opt/InCharge9/IP/smarts/regional/conf/discovery/RIM_ForcedMaxSpeed.conf.bkp"
  if system("#{cmd}")
    puts "successfully created a backup of the conf file"
  end

  cmd="scp /root/smangam/RIM_ForcedMaxSpeed.conf root@#{$cdm}:/opt/InCharge9/IP/smarts/regional/conf/discovery/RIM_ForcedMaxSpeed.conf"
  if system("#{cmd}")
    puts "successfully pushed RIM_ForcedMaxSpeed.conf"
  end
end

def if_snmp
   print "Enter device IP address:"
   ip=gets.chomp
   print "Enter SNMP Community String:"
   community=gets.chomp
   print "Enter ifdescr/ifadmin/ifoper:"
   oidstring=gets.chomp
   cmd = "ssh root@"+$cdm+ " snmpwalk -v2c -c " + community + " " + ip + " #{oidstring}"
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
   1: search for an device
   2: list all classes
   3: list devices for a given class (you should enter the class)
   4: list properties of a given device
   5: list important properties of a given device
   6: list InstrumentedBy property of a given device
   7: list all devices for a given sysobjectid in CDM: #{$cdm}
   8: list all devices for a given sysobjectid in all CDMs
 DEVICE SNMPWALK 
   20: list all agent nodes
   21: list agent nodes using search string
   22: test snmpwalk v2 and ping on a device
   23: test snmpwalk v3 and ping on a device
 ENABLE/DISABLE TRACING/DEBUGGING
   40: Enable/Disable debugging for APM
   41: Enable SNMP Accessor Dump for a device
   42: Disable SNMP Accessor Dump for a device
 DEVICE DISCOVERY
   50: print status of discovery process (prints discovery pending devices)
   51: print pending discovery list
   52: add a device directly to APM (use this when discovery fails)
   53: execute discovery of pending devices
 EXIT Program
   9: Exit"
  case gets.strip
  when "0"
    Didatacommon.get_cdm
  when "1"
    search_instances
  when "2"
    get_classes
  when "3"
    get_instances
  when "4"
    get_instance_properties
  when "5"
    get_instance_properties_selected
  when "6"
    get_instance_property_instrumentedby
  when "7"
    print "enter sysobjectid:"
    sysobjectid=gets.chomp
    Didatacommon.apm_search_devices_by_sysobjectid($cdm,sysobjectid)
  when "8"
    Didatacommon.apm_search_devices_by_sysobjectid_all
  when "40"
    enable_debug
  when "41"
    enable_SNMP_accessor_dump
  when "42"
    disable_SNMP_accessor_dump
  when "20"
    list_agents
  when "21"
    search_agents
  when "22"
    test_snmpv2
  when "23"
    test_snmpv3
  when "50"
    discovery_status
  when "51"
    discovery_pending_list
  when "52"
   discovery_add_device_snmpv2
  when "53"
   discover_pending
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
   Didatacommon.get_cdm 
  end
end

