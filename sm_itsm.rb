#!/usr/bin/ruby

$menu=0

def get_cdm
  print "Please enter the CDM (example am-goldcorp):"
  $cdm = gets.chomp
  $CDM = $cdm.upcase
  $APMserver = "AMCDM_"+$CDM+"_APM"
end

def get_synapse_status
  cmd="ssh root@#{$cdm} service synapse status"
  puts `#{cmd}`
  puts "synapse status(2 services must be running):"
  cmd="ssh root@#{$cdm} ps -eaf|grep synapse"
  puts `#{cmd}`
end

def get_synapse_start
  puts "enter start/stop:"
  input=gets.chomp
  cmd="ssh root@#{$cdm} service synapse #{input}"
  puts `#{cmd}`
end

def get_synapse_ports
  cmd="ssh root@#{$cdm} ps -eaf|grep synapse"
  puts `#{cmd}`
  print "enter sypanse pid:"
  pid = gets.chomp
  cmd="ssh root@#{$cdm} netstat -anp |grep #{pid}"
  puts `#{cmd}`
end

def get_synapse_log
  cmd="ssh root@#{$cdm} tail -n 20 /opt/synapse-2.0.0/logs/wrapper.log"
  puts `#{cmd}`
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

def mainmenu
 puts "select an option
   0: enter CDM
 Synapse Information (synapse is used for ITSM communications check)
   1: check synapse service
   2: start/stop synapse service
   3: list listening ports for synapse
   4: tail last 20 lines of wrapper.log for #{$cdm}
 Ping and SNMPWALK Test 
   10: test snmpwalk v2 and ping on a device
   11: test snmpwalk v3 and ping on a device
 Device Deployment Information
   30: find device driver used in other CDMs
   31: was the device discovered under a different name?
   32: is the device sysobjectid supported by any driver?
   33: is the device sysobjectid supported by any driver in other CDMs?
 EXIT Program
   9: Exit"
  case gets.strip
  when "0"
    get_cdm
  when "1"
    get_synapse_status
  when "2"
    get_synapse_start
  when "3"
    get_synapse_ports
  when "4"
    get_synapse_log
  when "10"
    test_snmpv2
  when "11"
    test_snmpv3
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

