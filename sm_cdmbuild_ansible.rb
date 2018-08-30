#!/usr/bin/ruby

require '/root/smangam/didatacommon'

mycommon = Didatacommon
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
   cmd = "ssh root@"+$cdm +" dmctl -s "+ $APMserver + " geti ICIM_NetworkAdapter"
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

def show_certification
  print "enter cdm:"
  mycdm=gets.chomp
  print "enter sysobjectid or model:"
  mymodel=gets.chomp
  certdir=["/opt/InCharge9/IP/smarts/regional/conf/discovery/oid2type_Field.conf","/opt/InCharge9/IP/smarts/conf/discovery/oid*conf"]
  certdir.each { |mydir|
    cmd="ssh root@#{mycdm} grep #{mymodel} #{mydir}"
    if system("#{cmd}")
      cmd="ssh root@#{mycdm} grep -h -A25 -B3 #{mymodel} #{mydir}"
      output=`#{cmd}`
      puts "#{mycdm} #{output}"
    end
  }
end

def pull_custom_oidfile
  cmd="scp root@#{$cdm}:/opt/InCharge9/IP/smarts/regional/conf/discovery/oid2type_Field.conf /root/smangam"
  if system("#{cmd}")
    puts "successfully pulled #{$cdm}:/opt/InCharge9/IP/smarts/regional/conf/discovery/oid2type_Field.conf"
  end
end

def push_custom_oidfile
  cmd="ssh root@#{$cdm} cp -p /opt/InCharge9/IP/smarts/regional/conf/discovery/oid2type_Field.conf /opt/InCharge9/IP/smarts/regional/conf/discovery/oid2type_Field.conf.bkp"
  if system("#{cmd}")
    puts "successfully created a backup of the conf file"
  end
  
  cmd="scp /root/smangam/oid2type_Field.conf root@#{$cdm}:/opt/InCharge9/IP/smarts/regional/conf/discovery/oid2type_Field.conf"
  if system("#{cmd}")
    puts "successfully pushed oid2type_Field.conf"
  end
end

def device_discovery
  print "enter device name:"
  device=gets.chomp
  cmd="ssh root@#{$cdm} dmctl -s #{$APMserver} invoke ICF_TopologyManager::ICF-TopologyManager rediscover Node::#{device}"
  system("#{cmd}")
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

def device_oidinfo
  print "enter device name:"
  device=gets.chomp
  cmd = "ssh root@"+$cdm +" dmctl -s "+ $APMserver + " get  ICIM_UnitaryComputerSystem::#{device}::CreationClassName"
  type=`#{cmd}`.chomp
  f=File.new("/root/smangam/myoidInfo.conf","a")
  f.puts "pollingInterval = 240"
  f.puts "snmpTimeout = 500"
  f.puts "#{type} #{device} All"
  f.close
  cmd="scp /root/smangam/myoidInfo.conf #{$cdm}:/opt/InCharge9/SAM/smarts"
  puts `#{cmd}`
  cmd="ssh root@#{$cdm} sm_perl /opt/In*/IP/smarts/bin/sm_oidInfo.pl -s #{$APMserver} -i /opt/InCharge9/SAM/smarts/myoidInfo.conf -d"
  puts "use admin/gsoa4ever to login"
  system("#{cmd}")
  cmd="rm -rf /root/smangam/myoidInfo.conf"
  `#{cmd}`
end


def mainmenu
 puts "select an option
 Run Ansible Playbooks
   1: list contents of /etc/ansible/hosts
   2: add CDM (base or solo) to the [New-Multi-T] section of /etc/ansible/hosts
   3: deploy qualys
   4: deploy cloudstrike
 EXIT Program
   9: Exit"
  case gets.strip
  when "1"
   Didatacommon.ansible_list_ansible_hosts_file
  when "3"
   Didatacommon.ansible_deploy_qualys
  when "4"
   Didatacommon.ansible_deploy_crowdstrike
  when "9"
    $menu=1
    puts "exiting..."
    exit
  end
end

while $menu==0
  mainmenu
end

