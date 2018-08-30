#!/usr/bin/ruby

module Didatacommon

require 'open3'

=begin

defined global variables
$cdm
$CDM
$cdm_fqdn
$APMserver
$ipaddress
$cdm_type
$basecdm
$tenantcdm
#$device
#$cdm_base_type
#$cdm_opt_freemb
#$cdm_root_freemb

files used
/root/smangam/mycdm.txt - used to store current CDM
/root/smangam/cdm_hosts_all.txt - all hosts in didata

=end

# global variables
$cdm_tenant_list=[]
$site_pp_path="/etc/puppet/manifests/site.pp"
$hieradata_node_dir="/etc/puppet/environments/branches_RIM_9_4_1_0/hieradata/node"
$samlog_days_keep=30
$num_of_ncm_dataimages=3

# NCM global variables
$ncmappservers=["amcdlncmapp01","amcdlncmapp02","amcdlncmapp03","amcdlncmapp04"]
$ncmdbservers=["amcalncmdb01","amcalncmdb02","amcalncmdb03","amcalncmdb04"]
$pgsql="/opt/smarts-ncm/db/controldb/bin/psql -d voyencedb -U voyence"


def self.get_cdm
  fr=File.new("/root/smangam/mycdm.txt")
    print "recent CDM is: "+fr.gets
  fr.close
  print "enter cdm:"
  $cdm=gets.chomp.downcase
  $CDM=$cdm.upcase
  $cdm_fqdn="#{$cdm}.us.gsoa.local"
  $APMserver = "AMCDM_"+$CDM+"_APM"
  f=File.new("/root/smangam/mycdm.txt","w")
  f.puts $cdm
  f.close

  if !host_exists?($cdm)
    print "#{$cdm} does not exist or is not reachable\n"
    return
  end
  host_env($cdm)
  puts "#{$cdm} CDM type is #{$cdm_type}"
  puts "tenant cdm is #{$tenantcdm}. base cdm is #{$basecdm}" if $cdm_type=="multi"
  puts "the tenants in the base cdm #{$basecdm} are: " +$cdm_tenant_list.to_s if $cdm_type=="base"
  puts "internal IP address for #{$cdm} is #{$ipaddress} on interface #{$internal_interface}"
  if $apg_cdm_dbhost!=nil
    puts "\nAPG Server details:"
    puts "#{$cdm} is on APG Database host #{$apg_cdm_dbhost} in database #{$apg_cdm_db}"
    puts "The Backend for #{$cdm} is #{$apg_cdm_backend_host} on port #{$apg_cdm_backend_port}"
  end
  puts "\nNCM Server details:"
  puts "NCM as server for #{$cdm} is #{$ncm_appserver} (#{$ncm_appserver_ip})"
  puts "NCM db server for #{$cdm} is #{$ncm_dbserver} (#{$ncm_dbserver_ip})"
  puts "\n"
end

def self.host_exists?(cdm)
  cmd="ssh -o 'PreferredAuthentications=publickey' root@#{cdm}  hostname >/dev/null 2>&1"
  if system("#{cmd}")
   true
  else
   false
  end
end

def self.host_exists_in_dns?(cdm)
  cmd="nslookup #{cdm} >/dev/null 2>&1"
  if system("#{cmd}")
   true
  else
   false
  end
end

def self.host_env(cdm)
  if host_exists?(cdm)
    cdm_type(cdm)
    cdm_std_dirs(cdm)
    apg_cdm_dbhost(cdm)
    apg_cdm_backend(cdm)
    ncm_get_cdm_as_db_server(cdm)
    fs_freemb(cdm)
  end
end

def self.get_date
  cmd="date"
  puts "Today's date is: "+`#{cmd}`
end

def self.file_exists?(cdm,filepath)
  cmd="ssh root@#{cdm} ls #{filepath} &>/dev/null"
  if system("#{cmd}")
   true
  else
   false
  end
end

def self.cdm_type(cdm)
  cmd="ssh root@#{cdm} ip a s|grep 'inet 152'|grep -v 'secondary'|awk '{print $2}'|cut -d'/' -f1"
  $ipaddress=`#{cmd}`.chomp

  cmd="ssh root@#{cdm} ip a s|grep 'inet 152'|wc -l"
  $internal_interface_count=`#{cmd}`.chomp.to_i
  if $internal_interface_count > 1
    $cdm_type="base"
    $basecdm=$cdm
  end

  if $cdm_type=="base" 
    cmd="ssh root@#{$cdm} ip a s|grep 'inet 152'|grep secondary|awk '{print $2}'|cut -d'/' -f1"
    $cdm_tenant_list_ip=`#{cmd}`.chomp.split
    $cdm_tenant_list_ip.each { |x|
      cmd="host #{x}|head -1|awk '{print $5}'|cut -d'.' -f1"
      host=`#{cmd}`.chomp
      $cdm_tenant_list << host
    }
  end

  cmd="ssh root@#{cdm} ip a s|grep 'inet 152'|grep -v 'secondary'|awk '{print $7}'"
  $internal_interface=`#{cmd}`.chomp
  if $internal_interface =~ /^v/
    $cdm_type="multi"
    $tenantcdm=$cdm
    cmd="nslookup #{$ipaddress}|grep name|grep -v #{$tenantcdm}.us.gsoa.local|awk '{print $4}'|cut -d'.' -f2"
    $basecdm=`#{cmd}`.chomp
  else
    $cdm_type="solo" if $cdm_type!="base"
  end
end

def self.get_device
  fr=File.new("/root/smangam/mydevice.txt")
  print "recent device is: "+fr.gets
  fr.close
  print "enter device name:"
  $device=gets.chomp
  print "enter device ip address:"
  $ipaddress=gets.chomp
end

def self.cdm_build_list
 cdm_solo_str = `grep "^node" /etc/puppet/manifests/site.pp |grep 'am-'|awk '{print $2}' | sed "s/\'//g" |sed "s/\.us\.gsoa\.local//g"`
 cdm_cal_str = `grep "^node" /etc/puppet/manifests/site.pp |grep 'amc'|awk '{print $2}' | sed "s/\'//g" |sed "s/\.us\.gsoa\.local//g"`
 cdm_multi_str = `grep "am-" /etc/puppet/manifests/site.pp | grep "=>" |grep -v "#" | sed 's/\"//g'| awk '{print $1}' |sed "s/ //g"`

 cdm_solo_arr = cdm_solo_str.split.sort!
 cdm_cal_arr = cdm_cal_str.split.sort!
 cdm_multi_arr = cdm_multi_str.split.sort!
 cdm_multi_base_arr = []

 #check if ssh to the host is working
 cdm_solo_arr.each do |cdm|
  if !(host_exists?(cdm)) then
   cdm_solo_arr -= [cdm]
  end
 end
 cdm_multi_arr.each do |cdm|
  if !(host_exists?(cdm)) then
   cdm_cal_arr -= [cdm]
  end
 end
 cdm_cal_arr.each do |cdm|
  if !(host_exists?(cdm)) then
   cdm_cal_arr -= [cdm]
  end
 end

 #check if any cdm is a multiT base CDM
 cdm_solo_arr.each do |cdm|
   cmd="ssh root@#{cdm} ip a s|grep 'inet 152'|wc -l"
   internal_interface_count=`#{cmd}`.chomp.to_i

   if internal_interface_count > 1
     cdm_solo_arr -= [cdm]
     cdm_multi_base_arr += [cdm]
   end
 end

 File.open("/root/smangam/cdm_solo.txt","w") do |f|
  f.puts cdm_solo_arr
  f.close
 end
 File.open("/root/smangam/cdm_multi.txt","w") do |f|
  f.puts cdm_multi_arr
  f.close
 end
 File.open("/root/smangam/cdm_multi_base.txt","w") do |f|
  f.puts cdm_multi_base_arr
  f.close
 end
 File.open("/root/smangam/cdm_cal.txt","w") do |f|
  f.puts cdm_cal_arr
  f.close
 end
 f=File.open("/root/smangam/cdm_customers_all.txt","w")
 f.puts `cat /root/smangam/cdm_solo.txt`
 f.puts `cat /root/smangam/cdm_multi.txt`
 f.close
 f=File.open("/root/smangam/cdm_hosts_all.txt","w")
 f.puts `cat /root/smangam/cdm_solo.txt`
 f.puts `cat /root/smangam/cdm_multi.txt`
 f.puts `cat /root/smangam/cdm_multi_base.txt`
 f.puts `cat /root/smangam/cdm_cal.txt`
 f.close
end

# this method should only be called from host_exists?()
def self.cdm_std_dirs(cdm)
 apg_std_dirs(cdm)
 ncm_std_dirs(cdm)
 if $cdm_type=="multi"
   $samdir  = "/opt/InCharge9/SAM/smarts/customer/#{cdm}/logs"
   $icoidir = "/opt/InCharge9/SAM/smarts/customer/#{cdm}/conf/icoi"
 elsif $cdm_type=="solo"
   $samdir  = "/opt/InCharge9/SAM/smarts/regional/logs"
   $icoidir = "/opt/InCharge9/SAM/smarts/regional/conf/icoi"
 end
end

############################################
# OS performance metrics
############################################

def self.cpu_usage
  puts "the first report is the data from the boot time or last time the iostat command was run"
  puts "use the last line to check the CPU load"
  puts "%idle must be > 10%"
  cmd="ssh root@#{$cdm}  iostat -cty 1 3"
  puts `#{cmd}`
end

def self.fs_status
  cmd = "ssh root@#{$cdm} df -m"
  puts `#{cmd}`
end

def self.fs_freemb(cdm)
 cmd="ssh root@#{cdm} df -m|grep '/opt'|awk '{print $4}'"
 $cdm_opt_freemb=`#{cmd}`.chomp.to_i
 cmd="ssh root@#{cdm} df -m|grep '/opt'|awk '{print $5}'|sed s/%//g"
 $cdm_opt_usedpercent=`#{cmd}`.chomp.to_i

 cmd="ssh root@#{cdm} df -m|grep '/var'|awk '{print $4}'"
 $cdm_var_freemb=`#{cmd}`.chomp.to_i
 cmd="ssh root@#{cdm} df -m|grep '/var'|awk '{print $5}'|sed s/%//g"
 $cdm_var_usedpercent=`#{cmd}`.chomp.to_i

 cmd="ssh root@#{cdm} df -m|grep '/$'|awk '{print $4}'"
 $cdm_root_freemb=`#{cmd}`.chomp.to_i
 cmd="ssh root@#{cdm} df -m|grep '/$'|awk '{print $5}'|sed s/%//g"
 $cdm_root_usedpercent=`#{cmd}`.chomp.to_i
end

def self.du_status
 print "enter the path(/*,/opt/* for example) to get disk usage:"
 du_path=gets.chomp
 cmd="ssh root@#{$cdm} du -khs #{du_path} 2>/dev/null"
 puts cmd
 puts `#{cmd}`
end

def self.ls_status
 print "enter the path(/*,/opt/* for example) to get ls -ltr status:"
 ls_path=gets.chomp
 cmd="ssh root@#{$cdm} ls -ltr #{ls_path}"
 puts cmd
 puts `#{cmd}`
end

def self.delete_file
 print "enter the complete path of file to be deleted:"
 file_path=gets.chomp
 cmd="ssh root@#{$cdm} ls -ltr #{file_path}"
 puts `#{cmd}`
 print "do you want to delete this file?(y/n):"
 output=gets.chomp
 if output=='y'
   puts "deleting file #{file_path}"
   cmd="ssh root@#{$cdm} rm -rf #{file_path}"
   puts cmd
   puts `#{cmd}`
 end
end

def self.fs_status_all
  printf("%-20s %-20s %-20s %-20s %-20s %-20s %-20s\n","cdm","opt_usedpercent","var_usedpercent", "root_usedpercent","opt_freemb","var_freemb","root_freemb")
  File.open("/root/smangam/cdm_hosts_all.txt").each { |a|
   x=a.chomp
   fs_freemb(x)
   if $cdm_opt_usedpercent > 89 or $cdm_var_usedpercent > 89 or $cdm_root_usedpercent > 89
     printf("%-20s %-20s %-20s %-20s %-20s %-20s %-20s\n",x,$cdm_opt_usedpercent,$cdm_var_usedpercent, $cdm_root_usedpercent, $cdm_opt_freemb, $cdm_var_freemb, $cdm_root_freemb)
   end 
 }
end

def self.fs_cleanup_all
  File.open("/root/smangam/cdm_hosts_all.txt").each { |a|
   x=a.chomp
   fs_freemb(x)
   if $cdm_opt_usedpercent > 89 or $cdm_var_usedpercent > 89 or $cdm_root_usedpercent > 89
     fs_cleanup(x)
   end
  }
end

def self.fs_cleanup(cdm)
  host_env(cdm)

  # check if APG qdf data is filling up
  qdf_count=apg_cdm_failover_filter_qdf_count(cdm)
  if (qdf_count.to_i > 10)
      puts "DISK FULL for #{cdm} due to APG qdf files filling up. Total files: #{qdf_count} "
  end

  #delete samlog logs that are older than 31 days and larger than 1M
  if file_exists?(cdm,"#{$samdir}")
    cmd = "ssh root@"+cdm +" find #{$samdir} -mtime +#{$samlog_days_keep} -size +1M 2>/dev/null"
    output = `#{cmd}`
    if ($?.success?) then
      puts "deleting samlog files older than #{$samlog_days_keep} days for #{cdm} "
      output_arr = output.split(/\n/)
      output_arr.each { |f|
        cmd = "ssh root@"+cdm +" rm -rf #{f}"
        `#{cmd}`
      }
    end
  end

  # delete samlog archive logs that are older than 10 days and larger than 1M
  if file_exists?(cdm,"#{$samdir}")
    cmd = "ssh root@"+cdm +" find #{$samdir}/archives -mtime +10 -size +1M"
    output = `#{cmd}`
    if ($?.success?) then
      puts "deleting samlog archive files older than 10 days for #{cdm} "
      output_arr = output.split(/\n/)
      output_arr.each { |f|
        cmd = "ssh root@"+cdm +" rm -rf #{f}"
        `#{cmd}`
      }
    end
  end

  # gzip the samlog that are older than 7 days and larger than 1M
  if file_exists?(cdm,"#{$samdir}")
    cmd = "ssh root@"+cdm +" find #{$samdir} -mtime +7 -size +1M|grep -v '.gz'"
    output = `#{cmd}`
    if ($?.success?) then
      puts "zipping the file for #{cdm} "
      output_arr = output.split(/\n/)
      output_arr.each { |f|
        cmd = "ssh root@"+cdm +" gzip #{f}"
        `#{cmd}`
      }
    end
  end

  # clear the samlog audit archive logs
  if file_exists?(cdm,"#{$samdir}/archives/*audit*")  
    cmd = "ssh root@"+cdm +" du -ks #{$samdir}/archives/*audit* | wc -l 2>/dev/null"
    output = `#{cmd}`.chomp
    if (output.to_i > 4) then
      puts "deleting audit files for #{cdm} "
      cmd = "ssh root@"+cdm +" rm -rf #{$samdir}/archives/*audit*"
      `#{cmd}`
    end
  end
  
  # clear ncm date-images
  if file_exists?(cdm,"/opt/smarts-ncm/data-image")  
    cmd = "ssh root@"+cdm +" ls -ltr /opt/smarts-ncm/data-image|grep -v total| wc -l"
    output = `#{cmd}`.chomp
    if (output.to_i > $num_of_ncm_dataimages.to_i) then
      # keep only the recent 5 backups
      files_to_delete = output.to_i - $num_of_ncm_dataimages.to_i
      cmd = "ssh root@"+cdm +" ls -ltr /opt/smarts-ncm/data-image |grep -v total | head -n #{files_to_delete}"
      output = `#{cmd}`
      output_arr = output.split(/\n/)
      output_arr.each do |f|
        myfile = f.split(/\s+/)
        puts "deleting file for #{cdm} " + myfile[-1]
        cmd = "ssh root@"+cdm +" rm -rf /opt/smarts-ncm/data-image/"+ myfile[-1]
        `#{cmd}`
      end
    end
  end

  # delete ncmcore logs if larger than 5GB
  if file_exists?(cdm,"/opt/smarts-ncm/ncmcore/logs/catalina.out")
    cmd = "ssh root@"+cdm +" find /opt/smarts-ncm/ncmcore/logs/catalina.out -size +5G 2>/dev/null"
    output = `#{cmd}`
    if ($?.success?) then
      puts "size of /opt/smarts-ncm/ncmcore/logs/catalina.out is >5GB. deleting... for #{cdm} "
      output_arr = output.split(/\n/)
      output_arr.each do |f|
        cmd = "ssh root@"+cdm +" rm -rf #{f}"
        puts cmd
        `#{cmd}`
      end
    end
  end

  # delete java core files
  if file_exists?(cdm,"/opt/smarts-ncm/ncmcore/java_pid*hprof")
    cmd = "ssh root@"+cdm +" find /opt/smarts-ncm/ncmcore/java_pid*hprof -size +1G 2>/dev/null"
    output = `#{cmd}`
    if ($?.success?) then
      puts "size of /opt/smarts-ncm/ncmcore/java_pid*hprof is >1GB. deleting... for #{cdm} "
      output_arr = output.split(/\n/)
      output_arr.each do |f|
        cmd = "ssh root@"+cdm +" rm -rf #{f}"
        puts cmd
        `#{cmd}`
      end
    end
  end

  # delete ncmcore logs
  if file_exists?(cdm,"/opt/smarts-ncm/ncmcore/logs/*")
    cmd = "ssh root@"+cdm +" find /opt/smarts-ncm/ncmcore/logs/* -mtime +31 2>/dev/null"
    output = `#{cmd}`
    if ($?.success?) then
      puts "deleted logs older than 31 days in /opt/smarts-ncm/ncmcore/logs for #{cdm} "
      output_arr = output.split(/\n/)
      output_arr.each do |f|
        cmd = "ssh root@"+cdm +" rm -rf #{f}"
        puts cmd
        `#{cmd}`
      end
    end
  end

  # delete ncmcore logs
  if file_exists?(cdm,"/usr/tomcat/apache-tomcat*/logs/*")
    cmd = "ssh root@"+cdm +" find /usr/tomcat/apache-tomcat*/logs/* -mtime +31 2>/dev/null"
    output = `#{cmd}`
    if ($?.success?) then
      puts "deleted logs older than 31 days in /usr/tomcat/apache-tomcat-8.0.23/logs for #{cdm} "
      output_arr = output.split(/\n/)
      output_arr.each do |f|
        cmd = "ssh root@"+cdm +" rm -rf #{f}"
        puts cmd
        `#{cmd}`
      end
    end
  end

  # cleanup /var dir
  if (file_exists?(cdm,"/var")) 
   cmd = "ssh root@"+cdm +" find /var/log/* -mtime +31 2>/dev/null"
   output = `#{cmd}`
   if ($?.success?) then
     puts "deleting /var/log files older than 31 days for #{cdm}"
     output_arr = output.split(/\n/)
     output_arr.each { |f|
       cmd = "ssh root@"+cdm +" rm -rf #{f}"
        `#{cmd}`
      }
   end
  end
  
  # delete files in /opt/rim/installers
  if file_exists?(cdm,"/opt/rim/installers/*")  
    cmd = "ssh root@"+cdm +" rm -rf /opt/rim/installers/*"
    print "deleting files in /opt/rim/installers"
    puts `#{cmd}`
  end
end

###########################
# raw disk and LVM info
###########################

def self.get_raw_device
  cmd = "ssh root@"+$cdm +" fdisk -l |grep Disk|grep dev|grep -v mapper"
  puts "list of devices (a device is a complete raw disk)"
  puts `#{cmd}`
end 

def self.get_device_partitions
  puts "about partitions: a partition on a device can be of type primary, logical, or extended"
  puts "you can have 3 primary partitions per device, and 1 extended parttion."
  puts "you can have several logical partitions in the extended partition. each logical partition is numbered from 5 onwards"
  puts "each partition has a fs-type: for example, boot,lvm,ext3,ext4,etc"
  puts "if the partition fs-type is LVM, you can create a PV on that partition"
  puts "if the partition fs-type is ext3/ext4, you can create a ext3/ext4 filesystem on that partition"
  puts "you can create more partitions on a device, if total space of existing partition is less than the total size of the device"
  puts " "
  print "enter device (/dev/sda etc):"
  device=gets.chomp
  cmd = "ssh root@"+$cdm +" fdisk -l #{device}"
  print "list of partitions in device  #{device}"
  puts `#{cmd}`
  cmd = "ssh root@"+$cdm +" parted #{device} print"
  print "list of partitions in device  #{device}"
  puts `#{cmd}`
end 

def self.create_lvm_partition_help
  message=<<-HERE
   on host, execute 'cfdisk <device>' example 'cfdisk /dev/sda'
   select the line with 'Free Space', choose New, and hit enter
   select Primary, if this is the 2nd or 3rd partition
   select Extended, if this is the 4th partition
   select Logical, if this is the 5th partition   
   select Type to change the FS type
   enter 8E to change the FS type to LVM
   select write
   select quit
   check a new partition is created using fdisk -l
  HERE
  puts message
end

def self.create_pv_help
  puts "pvcreate <partition>"
  puts "pvcreate /dev/sda3"
  puts "in case of error partprobe /dev/sda"
  puts "or partx /dev/sda"
end

def self.add_pv_to_vg_help
  message=<<-HERE
   vgextend vg pv
   vgextend VolGroup00 /dev/sda3
  HERE
  puts message
end

def self.extend_lv_help
 puts "lvextend -L +3G lvname_with_path"
 puts "lvextend -L +5G /dev/VolGroup00/opt"
 puts "resize2fs /dev/VolGroup00/opt"
end

def self.get_vgs
  cmd = "ssh root@"+$cdm +" vgs -v"
  puts "list of volume groups"
  puts `#{cmd}`
end 

def self.get_pvs
  cmd = "ssh root@"+$cdm +" pvs -v"
  puts "list of PVs"
  puts `#{cmd}`
end 

def self.get_lvs
  cmd = "ssh root@"+$cdm +" lvs -v"
  puts "list of LVs"
  puts `#{cmd}`
end 


##############################################
# ping,snmpwalk, ssh, telnet methods to a device
##############################################

def self.test_ping
   print "enter ip address:"
   $device_ipaddress=gets.chomp
   cmd = "ssh root@"+$cdm+ " ping -c 3 " + $device_ipaddress
   output=`#{cmd}`
   puts output
end

def self.test_snmpv2
   print "enter ip address:"
   $device_ipaddress=gets.chomp
   print "Enter SNMP Community String:"
   community=gets.chomp
   cmd = "ssh root@"+$cdm+ " snmpwalk -v2c -c " + community + " " + $device_ipaddress + " sysobjectid"
   output=`#{cmd}`
   puts output
end

def self.test_snmpv3
   print "Enter device IP address:"
   ip=gets.chomp
   print "Enter user name:"
   user=gets.chomp
   print "Enter authentication protocol (SHA or MD5):"
   auth_protocol=gets.chomp
   print "Enter authentication password:"
   auth_password=gets.chomp
   print "Enter authentication(security) level(NoAuthNoPriv,authNoPriv,authPriv):"
   auth_level=gets.chomp
   print "Enter privilege protocol:"
   priv_protocol=gets.chomp
   print "Enter privilege password:"
   priv_password=gets.chomp

   if priv_protocol == nil
    cmd = "ssh root@#{$cdm} snmpwalk -v3 -u #{user} -a #{auth_protocol} -A #{auth_password}  -l #{auth_level} #{ip} sysobjectid"
   else
    cmd = "ssh root@#{$cdm} snmpwalk -v3 -u #{user} -a #{auth_protocol} -A #{auth_password}  -X #{priv_password} -x #{priv_protocol} -l #{auth_level} #{ip} sysobjectid"
   end
   puts cmd
   output=`#{cmd}`
   puts output
   cmd = "ssh root@"+$cdm+ " ping -c 3 " + ip
   output=`#{cmd}`
   puts output
end

def self.validate_dns
  cmd="nslookup #{$cdm}"
  puts `#{cmd}`
  puts "execute a reverse lookup"
  print "enter CDM ip address:"
  ip=gets.chomp
  cmd="nslookup #{ip}"
  puts `#{cmd}`
end

def self.scp_file
  print "enter source file:"
  source=gets.chomp
  cmd="scp #{$cdm}:#{source} /root/smangam"
  system("#{cmd}")
end

############################
# SMARTS methods
############################

def self.sm_service
  print "enter show/start --all/stop --all/start <servicename>/stop <servicename>:"
  option=gets.chomp
  cmd="ssh root@#{$cdm} sm_service #{option}"
  puts cmd
  output=`#{cmd}`
  puts output
end

def self.check_cdm_in_broker
  cmd="ssh root@amcdlsam01 brcontrol|grep -i #{$cdm}"
  puts cmd
  puts `#{cmd}`
end

def self.sam_search_events
   print "enter CDM (enter all to search for all CDMs):"
   mycdm=gets.chomp.upcase
   print "Enter event search string: "
   inputstr = gets.chomp
   if mycdm == 'ALL'
     cmd="ssh root@amcdlsam01 dmctl -s AMCDL_SAM9990 geti ICIM_Notification| grep -i " + """'""" + inputstr + """'""" + " | awk '{print $1}'"
   else
     cmd="ssh root@amcdlsam01 dmctl -s AMCDL_SAM9990 geti ICIM_Notification|grep #{mycdm}| grep -i " + """'""" + inputstr + """'""" + " | awk '{print $1}'"
   end
   puts cmd
   puts `#{cmd}` 
end

###################################
# SMARTS OI Adapter
###################################

def self.notif_get_running_ncf_files
  cdm_std_dirs($cdm)
  cmd = "ssh root@#{$cdm} ls #{$icoidir}/*running.ncf|wc -l"
  count=`#{cmd}`.chomp.to_i
  if count == 1
    puts "NOTIF config file for #{$cdm} is:"
    cmd = "ssh root@#{$cdm} ls #{$icoidir}/*running.ncf"
    puts `#{cmd}` 
  elsif count > 1
    puts "ERROR!: multiple NOTIF config files exist. Only one should exist"
    cmd = "ssh root@#{$cdm} ls #{$icoidir}/*running.ncf"
    puts `#{cmd}` 
  else
    puts "ERROR!: no NOTIF config file fould"
    cmd = "ssh root@#{$cdm} ls #{$icoidir}/*running.ncf"
    puts `#{cmd}` 
  end
end

def self.notif_list_events
  cdm_std_dirs($cdm)
  print "enter event search string:"
  searchstr=gets.chomp
  cmd = "ssh root@#{$cdm} grep \"'<eci '\" -A1 #{$icoidir}/*running.ncf|grep -i #{searchstr}|sort|uniq"
  puts cmd
  puts `#{cmd}`
end

def self.notif_get_event_from_running_ncf
  cdm_std_dirs($cdm)
  print "enter event name:"
  searchstr=gets.chomp
  cmd = "ssh root@#{$cdm} grep -i -A17 -m 1 'eventname="+'\"'+searchstr+"' #{$icoidir}/*running.ncf"
  puts cmd
  puts `#{cmd}`
end

def self.notif_search_calcvalues_all_cdms
  print "enter event name:"
  searchstr=gets.chomp
  print "enter calculated value string (enter n to skip):"
  mycalcvalue=gets.chomp

  File.open("/root/smangam/cdm_solo.txt").each { |a|
   x=a.chomp
   cdm_std_dirs(x)
   if mycalcvalue == 'n'
    cmd = "ssh root@#{x} grep -i -A17 -m 1 'eventname="+'\"'+searchstr+"' #{$icoidir}/*running.ncf|grep CalculatedValues"
   else
    cmd = "ssh root@#{x} grep -i -A17 -m 1 'eventname="+'\"'+searchstr+"' #{$icoidir}/*running.ncf|grep CalculatedValues |grep #{mycalcvalue}"
   end
   output = `#{cmd}`.chomp
   if !output.empty?
    puts "#{x} has calculated values defined for event #{searchstr}"
   end
  }

 File.open("/root/smangam/cdm_multi.txt").each { |a|
   x=a.chomp
   cdm_std_dirs(x)
   if mycalcvalue == 'n'
    cmd = "ssh root@#{x} grep -i -A17 -m 1 'eventname="+'\"'+searchstr+"' #{$icoidir}/*running.ncf|grep CalculatedValues"
   else
    cmd = "ssh root@#{x} grep -i -A17 -m 1 'eventname="+'\"'+searchstr+"' #{$icoidir}/*running.ncf|grep CalculatedValues |grep #{mycalcvalue}"
   end
   output = `#{cmd}`.chomp
   if !output.empty?
    puts "#{x} has calculated values defined for event #{searchstr}"
   end
  }
end

def self.notif_get_notif_data_list
  cdm_std_dirs($cdm)
  print "enter search string:"
  searchstr=gets.chomp
  puts "list of files with #{searchstr}"
  cmd = "ssh root@#{$cdm} grep -ilr #{searchstr} #{$samdir} |grep -v Notif"
  puts cmd
  puts `#{cmd}`
end

def self.notif_get_notif_data_list_all
  print "enter search string:"
  searchstr=gets.chomp
  File.open("/root/smangam/cdm_solo.txt").each { |x|
    mycdm=x.chomp
    cdm_std_dirs(mycdm)
    cmd = "ssh root@#{mycdm} grep -ilr #{searchstr} #{$samdir}/* |grep -v Notif|grep -v running"
    if system("#{cmd}")
      puts "\nlist of files with #{searchstr} in #{mycdm}"
      cmd = "ssh root@#{mycdm} grep -ilr #{searchstr} #{$samdir}/* |grep -v Notif"
      puts `#{cmd}`

      puts "list of files with #{searchstr} in #{mycdm} archives directory"
      cmd = "ssh root@#{mycdm} zgrep -il #{searchstr} #{$samdir}/archives/* |grep -v Notif"
      puts `#{cmd}`
    end
  }
end

def self.notif_get_notif_data
  print "enter cdm:"
  mycdm=gets.chomp.downcase
  print "enter file to search(full path):"
  searchfile=gets.chomp
  print "enter search string:"
  searchstr=gets.chomp
  if searchfile =~ /gz$/
    cmd = "ssh root@#{mycdm} zgrep -i -B46  #{searchstr} #{searchfile}"
  else
    cmd = "ssh root@#{mycdm} grep -i -B46  #{searchstr} #{searchfile}"
  end
  puts cmd
  puts `#{cmd}`
end


###################################
# query Puppet manifests
###################################

def self.check_site_pp
  cmd="grep -i #{$cdm} #{$site_pp_path}"
  puts cmd
  puts `#{cmd}`
end
  
def self.get_cal
  cmd="grep -l #{$cdm.upcase} #{$hieradata_node_dir}/*yaml"
  puts cmd
  puts `#{cmd}`
end

#################################
# Deployment methods
#################################

def self.check_synapse
  cmd="ssh root@#{$cdm} systemctl status synapse"
  puts `#{cmd}`
end

def self.list_files_in_predeployarchive
  print "a file is created in /opt/rim/predeploymentDeviceSpoolArchive/ when you execute deploy from ITSM"
  print "use the timestamp to identify the file"
  cmd="ssh root@#{$cdm} ls -ltr /opt/rim/predeploymentDeviceSpoolArchive/* |tail -n 15"
  puts `#{cmd}`
  print "enter file name:"
  myfile=gets.chomp
  cmd="ssh root@#{$cdm} cat /opt/rim/predeploymentDeviceSpoolArchive/#{myfile}"
  puts `#{cmd}`
end

def self.check_predeployment_log
  cmd="ssh root@#{$cdm} tail -n 10 /opt/rim/PreDeploymentCheck.log"
  puts `#{cmd}`
end

def self.get_deployment_tomcat_log
  cmd="scp root@#{$cdm}:/opt/InCharge9/CONSOLE/smarts/regional/logs/sm_tomcat_en_US_UTF-8.log /root/smangam/"
  puts cmd
  puts `#{cmd}`
end

#################################
# NCM methods
#################################

def self.ncm_std_dirs(cdm)
  if file_exists?(cdm,"/etc/voyence.conf")
    cmd="ssh root@#{cdm} cat /etc/voyence.conf|grep VOYENCE_HOME=|cut -d'=' -f2"
    $ncm_voyence_home=`#{cmd}`.chomp
  end
end

#####################################
# NCM service related methods
#####################################
def self.get_ncm_status
  puts "NCM status for #{$cdm}"
  puts "the following 7 services should be up and running"
  puts "voyenced|sysmon|evdispatch|syssyncd|autodiscd|commmgr|zebedee"
  cmd="ssh root@#{$cdm} service vcmaster status"
  puts `#{cmd}`
  puts " "
  cmd="ssh root@#{$cdm} ps -eaf|egrep 'voyenced|sysmon|evdispatch|syssyncd|autodiscd|commmgr|zebedee'"
  puts `#{cmd}`
  puts " "
  puts "the following are the ports used by NCM"
  cmd="ssh root@#{$cdm} netstat -anp|grep 999"
  puts `#{cmd}`
end

def self.get_ncm_status_server
  print "enter NCM server:"
  mycdm=gets.chomp
  puts "the following 7 services should be up and running"
  puts "voyenced|sysmon|evdispatch|syssyncd|autodiscd|commmgr|zebedee"
  cmd="ssh root@#{mycdm} service vcmaster status"
  puts `#{cmd}`
  puts " "
  cmd="ssh root@#{mycdm} ps -eaf|egrep 'voyenced|sysmon|evdispatch|syssyncd|autodiscd|commmgr|zebedee'"
  puts `#{cmd}`
  puts " "
  puts "the following are the ports used by NCM"
  cmd="ssh root@#{mycdm} netstat -anp|grep 999"
  puts `#{cmd}`
end

def self.ncm_appserver_manage
  print "enter NCM server:"
  mycdm=gets.chomp
  cdm_type(mycdm)
  if $cdm_type=='multi'
    cmd="ssh root@#{mycdm} sm_service show"
    puts cmd
    puts `#{cmd}`
    print "enter show/start/stop:"
    manage=gets.chomp
    if manage=="show"
      cmd="ssh root@#{mycdm} sm_service #{manage}"
      puts cmd
      puts `#{cmd}`
    else
      print "enter service name:"
      myservice=gets.chomp
      cmd="ssh root@#{mycdm} sm_service #{manage} #{myservice}"
      puts cmd
      puts `#{cmd}`
    end
  else
    print "enter status/start/stop:"
    manage=gets.chomp
    cmd="ssh root@#{mycdm} systemctl #{manage} vcmaster"
    puts cmd
    puts `#{cmd}`
  end
end

def self.ncm_kill_process
  print "enter NCM server:"
  mycdm=gets.chomp
  puts "kill a process id on #{mycdm}"
  print "enter pid:"
  mypid=gets.chomp
  cmd="ssh root@#{mycdm} kill -9 #{mypid}"
  puts cmd
  puts `#{cmd}`
end

def self.ncm_unlock_lockbox
  puts "unlocking lockbox on #{$cdm}"
  cmd="ssh root@#{$cdm} /opt/rim/scripts/unlock_ncm_lockbox.sh"
  if system("#{cmd}")
    puts "success: #{cmd}"
  else
    puts "fail: #{cmd}"
  end
end

# method to get the AS and DB server for a given CDM
def self.ncm_get_cdm_as_db_server(cdm)
  ncm_std_dirs(cdm)
  cmd="ssh root@#{cdm} cat #{$ncm_voyence_home}/data/devserver/master.addr"
  $ncm_appserver_ip=`#{cmd}`.chomp
  cmd="ssh root@#{$ncm_appserver_ip} hostname -s"
  $ncm_appserver=`#{cmd}`.chomp

  # get ncm db server for the cdm
  # db server is set at app server level, not at CDM level 
  cmd="ssh root@#{$ncm_appserver} cat /etc/controldb.conf|grep DB_IP|cut -d'=' -f2"    
  $ncm_dbserver_ip=`#{cmd}`.chomp
  cmd="ssh root@#{$ncm_dbserver_ip} hostname -s"
  $ncm_dbserver=`#{cmd}`.chomp
end

def self.as_port_status
  puts "On the AS, the process syssyncd must be listening on port 9997"
  puts "if any connnection is in ESTABLISHED state, it indicates an error on the DS"
  cmd="ssh root@#{$ncm_appserver} netstat -anp|egrep 'voyenced|commmgrd|autodiscd|zebedee|syssyncd'"
  puts `#{cmd}`
end

def self.ds_port_status
 cmd="ssh root@#{$cdm} netstat -anp|egrep 'voyenced|commmgrd|autodiscd|zebedee|syssyncd'"
 puts `#{cmd}`
end


def self.ds_httpd_status
 puts "The service httpd must be running on the DS"
 cmd="ssh root@#{$cdm} ps -eaf|grep httpd"
 puts `#{cmd}`
end

def self.pending_jobs_AS_info
  puts "(1) you execute a config pull on the GUI for a given device"
  puts "    select the job. select the task. on history tab, note the time where it says 'Task started on CDM'(example:Task started on AM-VISTEON Nov 17 04:01:52). the time here is the appserver system time."
  puts " "
  puts "(2) when a job is executed on the GUI, the controldaemon creates a command script file (xml file) on AS in the directory /opt/smarts-ncm/data/appserver/pops/pop#/syssync/commmgr/toServer"
  puts "    Note that each DS is given a popnumber"
  puts "    list of command script files for #{$cdm} are created under /opt/smarts-ncm/data/appserver/pops/pop#{$popnumber}/syssync/commmgr/toServer"
  puts "    you should not see any command file here, since the command file gets moved to DS in a split second"
  puts " "
  puts "(3) the syssyncd process on AS detects the new command file automatically, and moves it to the DS, and after the move is completed, deletes from the AS"
  puts "    syssyncd process on AS makes an https call to DS, and calls ssxfri.cgi on DS to do the transfer"
  puts "    you should see similar 2 entries in the syssyncm.log. the time matches the time from (1)"
  puts "    /opt/smarts-ncm/logs/syssyncm.log:Nov 17 03:01:02 502888192#1: Update detected: /opt/smarts-ncm/data/appserver/pops/pop19721/syssync/commmgr/toServer/acmd_1015108876620143_986ef21ec073e83f7a20ecc75f010000_pull.xml"
  puts "    /opt/smarts-ncm/logs/syssyncm.log:Nov 17 03:01:02 502888192#1: Move: /opt/smarts-ncm/data/appserver/pops/pop19721/syssync/commmgr/toServer/acmd_1015108876620143_986ef21ec073e83f7a20ecc75f010000_pull.xml -> /opt/smarts-ncm/data/devserver/syssync/commmgr/toServer/acmd_1015108876620143_986ef21ec073e83f7a20ecc75f010000_pull.xml"
  puts "    if a command file fails in getting moved to DS, the job shows as running on the GUI"
  puts "    all subsequent jobs for a given DS do not get executed (will show as running in GUI), unless the first one in the list is cleared"
  puts "    these are the jobs waiting in queue only for DS #{$cdm}"
  puts "    the queue should be 0, else the new jobs will be 'Queued for execution'"
  puts " "
  puts "(4) the ssxfri log on DS has logs about the succcessful tranfer of command file to DS"
  puts "    Nov 17 04:01:49 -528082880#1: ======== ssxfrcgi pid 63896: started 9.4.1.0.75========"
  puts "    Nov 17 04:01:49 pid-528082880#1: In Server Mode: request came from 152.110.242.30 master"
  puts "    Nov 17 04:01:49 pid-528082880#1: mask=acmd_ and ret = 1"
  puts "    Nov 17 04:01:49 pid-528082880#1: Processing Master->Server file(acmd_1015108913080150_986ef21ef185db3f0dc423c85f010000_pull.xml) cmd(Create File) from(140728898420736)"
  puts "    Nov 17 04:01:49 pid-528082880#1: Creating acmd_1015108913080150_986ef21ef185db3f0dc423c85f010000_pull.xml"
  puts "    Nov 17 04:01:49 pid-528082880#1: Uploading file /opt/smarts-ncm/data/devserver/syssync/commmgr/toServer/.ssx_acmd_1015108913080150_986ef21ef185db3f0dc423c85f010000_pull.xml..."
  puts "     Nov 17 04:01:49 pid-528082880#1: Renaming /opt/smarts-ncm/data/devserver/syssync/commmgr/toServer/.ssx_acmd_1015108913080150_986ef21ef185db3f0dc423c85f010000_pull.xml -> .../acmd_1015108913080150_986ef21ef185db3f0dc423c85f010000_pull.xml"
  puts "     Nov 17 04:01:49 ssxfrcgi#1| 63896: -------- ssxfrcgi: stopped 9.4.1.0.75 --------"
  puts " "
  puts "(7) the syssyncd process on DS detects the command status and results files on DS and automatically, moves them to the AS, and after the move is successful, deletes them from DS" 
  puts "    Nov 17 17:38:22 1903089408#1: Update detected: /opt/smarts-ncm/data/devserver/syssync/commmgr/toMaster/task/acmd_5000064060_taskstatus.xml"
  puts "    Nov 17 17:38:22 1903089408#1: Move: /opt/smarts-ncm/data/devserver/syssync/commmgr/toMaster/task/acmd_5000064060_taskstatus.xml -> /opt/smarts-ncm/data/appserver/pops/pop6459/syssync/commmgr/toMaster/task/acmd_5000064060_taskstatus.xml"
  puts "    Nov 17 17:38:22 1903089408/acmd_5000064060_taskstatus.xml#2: Connecting to https://152.110.242.30:443/voyence-bin/ssxfr.cgi?from=6459&cmd=create&dir=%3adata%2fsyssync%2fcommmgr%2ftoMaster%2ftask&file=acmd_5000064060_taskstatus.xml"
  puts "    Nov 17 17:38:22 1903089408/acmd_5000064060_taskstatus.xml#2: Hostname: 152.110.242.30"
  puts "    Nov 17 17:38:22 1903089408/acmd_5000064060_taskstatus.xml#2: URI: /voyence-bin/ssxfr.cgi?from=6459&cmd=create&dir=%3adata%2fsyssync%2fcommmgr%2ftoMaster%2ftask&file=acmd_5000064060_taskstatus.xml"
 puts " "
 puts "(8) the status and results files are stored on AS in the toMaster/task directory, before they are updated in the PostgresSQL database. after successfully updating the database, the entries are deleted."
 puts "    cat acmd_5000073385_taskstatus.xml"
 puts '    <TaskStatusNotif  idx=24048 message-type="TASK_STATUS" network-id="986ef21e44b9e93f533f2ff35e010000" task-id="986ef21e35ffe73fd07768db5f010000#3458925" timestamp="1511215777" username="c3lzdGVt"><StatusMessage>"'
 puts "    <![CDATA["
 puts "    Executing :Get System Properties]]>"
 puts "    </StatusMessage></TaskStatusNotif>"

end

def self.test_opennssl_as_to_ds_connection
  print "testing openssl connection from #{$ncm_appserver} to #{$cdm}"
  cmd="ssh root@#{$ncm_appserver} openssl s_client -connect #{$cdm}:443 -CApath #{$ncm_voyence_home}/conf/CA/"
  puts `#{cmd}`
  puts " "
  print "testing openssl connection from #{$cdm} to #{$ncm_appserver}"
  cmd="ssh root@#{$cdm} openssl s_client -connect #{$ncm_appserver}:443 -CApath /opt/smarts-ncm/conf/CA/"
  puts `#{cmd}`
end

def self.pending_jobs_AS_all
 $ncmappservers.each {|appserver|
  f=File.new("/root/smangam/#{appserver}_pendingjobs.txt","w")
  puts "list of pending jobs stored in /root/smangam/#{appserver}_pendingjobs.txt"
  cmd="ssh root@#{appserver} ls /opt/smarts-ncm/data/appserver/pops"
  all_ds=`#{cmd}`.chomp.split
  all_ds.each { |x|
    cmd="ssh root@#{appserver} ls -ltr /opt/smarts-ncm/data/appserver/pops/#{x}/syssync/commmgr/toServer |egrep -v 'dsevents|total|status|healthcheck'|wc -l"
    count=`#{cmd}`.chomp
    if count.to_i > 0
      pop=x[3..-1]
      cmd="cat /root/smangam/#{appserver}_cflist.txt|grep '^POP'|grep #{pop}|awk '{print $3}'"
      cdm=`#{cmd}`.chomp
      f.puts "pending files for #{cdm} with pop# #{x}"
      cmd="ssh root@#{appserver} ls -ltr /opt/smarts-ncm/data/appserver/pops/#{x}/syssync/commmgr/toServer |grep -v dsevents|egrep -v 'dsevents|total|status|healthcheck'"
      f.puts `#{cmd}`
    end
  }
  f.close
 }
end

def self.pending_jobs_count_AS_all
 printf("%20s %-25s %-15s %-20s %-30s %-20s\n","appserver","cdm","pop#","total_pending_pull_jobs","oldest_pull_date","recent_pull_date")
 $ncmappservers.each {|appserver|
  cmd="ssh root@#{appserver} ls /opt/smarts-ncm/data/appserver/pops"
  all_ds=`#{cmd}`.chomp.split
  all_ds.each { |x|
    cmd="ssh root@#{appserver} ls -ltr /opt/smarts-ncm/data/appserver/pops/#{x}/syssync/commmgr/toServer |grep 'pull'|wc -l"
    count=`#{cmd}`.chomp
    if count.to_i > 0
      pop=x[3..-1]
      cmd="cat /root/smangam/#{appserver}_cflist.txt|grep '^POP'|awk '{print $1,$2,$3}'|grep '"+pop+" '|awk '{print $3}'"
      cdm=`#{cmd}`.chomp
      if cdm != nil or cdm!="" or cdm !=" "
        cmd="ssh root@#{appserver} ls -ltr --time-style=full-iso /opt/smarts-ncm/data/appserver/pops/#{x}/syssync/commmgr/toServer |grep 'pull'|head -n 1|awk '{print $6}'"
        oldest_pull_timestamp=`#{cmd}`.chomp
        cmd="ssh root@#{appserver} ls -ltr --time-style=full-iso /opt/smarts-ncm/data/appserver/pops/#{x}/syssync/commmgr/toServer |grep 'pull'|tail -n 1|awk '{print $6}'"
        recent_pull_timestamp=`#{cmd}`.chomp
        printf("%20s %-25s %-15s %-20s %-30s %-20s\n",appserver,cdm,pop,count,oldest_pull_timestamp,recent_pull_timestamp)
      end
    end
  }
 }
end

def self.ncm_pending_jobs_AS_cdm
  cmd="ssh root@#{$ncm_appserver} ls -ltr /opt/smarts-ncm/data/appserver/pops/pop#{$popnumber}/syssync/commmgr/toServer |grep -v dsevents|grep -v total|grep -v status|wc -l"
  puts cmd
  count=`#{cmd}`.chomp
  puts "total count of pending files: "+count
  if count.to_i > 0
    cmd="ssh root@#{$ncm_appserver} ls -ltr /opt/smarts-ncm/data/appserver/pops/pop#{$popnumber}/syssync/commmgr/toServer |grep -v dsevents|grep -v total"
    puts `#{cmd}`
  end
end

def self.ncm_search_job_in_syssyncm_AS
  print "enter command file or popid search string (example acmd_1015015564016119,pop1234):"
  mystr=gets.chomp
  print "discard healthcheck jobs?(y/n):"
  myresp=gets.chomp
  if myresp=='y'
    cmd="ssh root@#{$ncm_appserver} cat /opt/smarts-ncm/logs/syssyncm*log|grep -v healthcheck|grep #{mystr}"
  else
    cmd="ssh root@#{$ncm_appserver} grep #{mystr} /opt/smarts-ncm/logs/syssyncm*log"
  end
  puts cmd
  puts `#{cmd}`
end

def self.ncm_ssxfr_on_AS
  puts "the command file results from DS are transferred to AS"
  puts "Status of most recent data transfer. watch for the timestamp. an old timestamp indicates a problem"
  puts "current date/time is: "+`date`.chomp
  cmd="ssh root@#{$ncm_appserver} tail -n 1 /opt/smarts-ncm/logs/ssxfrcgi.log|awk '{print $1,$2,$3}'"
  puts "most recent data transfer timestamp is: "+`#{cmd}`.chomp

  puts "\ndata transfer list for #{$cdm}"
  cmd="ssh root@#{$ncm_appserver} grep #{$ipaddress} /opt/smarts-ncm/logs/ssxfrcgi.log"
  puts `#{cmd}`

  #puts "\ndata transfer list for #{$cdm} with more details"
  #cmd="ssh root@#{$ncm_appserver} grep #{$ipaddress} -A 5 /opt/smarts-ncm/logs/ssxfrcgi.log"
  #puts `#{cmd}`

  puts "\ndata transfer for a given pid"
  print "enter pid(example, pid591513664) or n to skip:"
  pid=gets.chomp
  if pid!='n'
   cmd="ssh root@#{$ncm_appserver} grep #{pid} -A 20 /opt/smarts-ncm/logs/ssxfrcgi.log"
   puts `#{cmd}`
  end
end

def self.ncm_ssxfr_on_DS
  puts "the AS process syssyncd calls ssxfr.cgi on DS, to transfer command file from AS and DS"
  puts "watch for the timestamp. an old timestamp indicates a problem"
  print "search for specific command file(example,acmd_1015108913080150), or enter a number to list last n lines:"
  myresp=gets.chomp
  if myresp == myresp.to_i.to_s
    cmd="ssh root@#{$cdm} tail -n #{myresp} #{$ncm_voyence_home}/logs/ssxfrcgi.log"
  else
    cmd="ssh root@#{$cdm} grep #{myresp} #{$ncm_voyence_home}/logs/ssxfrcgi.log"
  end
  puts cmd
  puts " "
  puts `#{cmd}`
end

def self.ncm_check_syssyncm_AS
  puts "check the log file syssyncm.log for any entries pertaining to the DS"
  cmd="ssh root@#{$ncm_appserver} grep pop#{$popnumber} /opt/smarts-ncm/logs/syssyncm.log"
  puts `#{cmd}`
end

def self.ncm_pending_jobs_DS
  puts "the command file tranferred from AS, is stored here, to be processed by commmgrd on DS"
  puts "all the jobs listed here are waiting in queue to be processed by commmgrd on DS"
  puts "the queue should be 0, else the new jobs will be 'Queued for execution'"
  puts "the command file here is processed by commmgrd on DS"
  puts " "
  cmd="ssh root@#{$cdm} ls -ltr #{$ncm_voyence_home}/data/devserver/syssync/commmgr/toServer"
  puts `#{cmd}`
  puts "total count of files"
  cmd="ssh root@#{$cdm} ls -ltr #{$ncm_voyence_home}/data/devserver/syssync/commmgr/toServer |wc -l"
  puts `#{cmd}`
  print "enter job file name to display (example,status_0115108027990000) or n to skip:"
  myfile=gets.chomp
  if myfile !='n'
    cmd="ssh root@#{$cdm} cat #{$ncm_voyence_home}/data/devserver/syssync/commmgr/toServer/#{myfile}"
    puts `#{cmd}`
  end
end

def self.ncm_tomaster_tasks_DS
  puts "on DS, the command file is processed by commmgrd, and the task files are created here"
  cmd="ssh root@#{$cdm} ls -ltr #{$ncm_voyence_home}/data/devserver/syssync/commmgr/toMaster/deviceupdate"
  puts `#{cmd}`
  puts "total count of files"
  cmd="ssh root@#{$cdm} ls -ltr #{$ncm_voyence_home}/data/devserver/syssync/commmgr/toMaster/deviceupdate |wc -l"
  puts `#{cmd}`
  print "show file (enter filename or n to skip):"
  myfile=gets.chomp
  if myfile !='n'
    cmd="ssh root@#{$cdm} cat #{$ncm_voyence_home}/data/devserver/syssync/commmgr/toMaster/deviceupdate/#{myfile} "
    puts `#{cmd}`
  end
end

def self.ncm_tomaster_results_DS
  puts "after commmgrd executes a acmd file, the status and results are in the task directory"
  puts "these results are sent to AS, to be stored in the database"
  cmd="ssh root@#{$cdm} ls -ltr #{$ncm_voyence_home}/data/devserver/syssync/commmgr/toMaster/task"
  puts cmd
  puts `#{cmd}`
  puts "total count of files"
  cmd="ssh root@#{$cdm} ls -ltr #{$ncm_voyence_home}/data/devserver/syssync/commmgr/toMaster/task |wc -l"
  puts `#{cmd}`
  print "show file (enter filename or n to skip):"
  myfile=gets.chomp
  if myfile !='n'
    cmd="ssh root@#{$cdm} cat #{$ncm_voyence_home}/data/devserver/syssync/commmgr/toMaster/task/#{myfile} "
    puts `#{cmd}`
  end
end

def self.ncm_tomaster_results_AS
  puts "the status and results files from the DS are stored here, before being pushed to the Postgresql database"
  cmd="ssh root@#{$ncm_appserver} ls -ltr /opt/smarts-ncm/data/appserver/pops/pop#{$popnumber}/syssync/commmgr/toMaster/task"
  puts cmd
  puts `#{cmd}`
  #puts "total count of files"
  #cmd="ssh root@#{$cdm} ls -ltr /opt/smarts-ncm/data/devserver/syssync/commmgr/toMaster/task |wc -l"
  #puts `#{cmd}`
  print "show file (enter filename or n to skip):"
  myfile=gets.chomp
  if myfile !='n'
    cmd="ssh root@#{$ncm_appserver} cat /opt/smarts-ncm/data/appserver/pops/pop#{$popnumber}/syssync/commmgr/toMaster/task/#{myfile}"
    puts `#{cmd}`
  end
end

def self.ncm_check_syssyncs_DS
  puts "the results obtained from executing the commands (by commmgrd) are sent to the AS"
  cmd="ssh root@#{$cdm} tail -n 80 #{$ncm_voyence_home}/logs/syssyncs.log"
  puts `#{cmd}`
end

def self.ncm_ds_idx_setting
  cmd="ssh root@#{$cdm} cat #{$ncm_voyence_home}/data/devserver/our.idx"
  puts cmd
  puts `#{cmd}`
end

########################################
# NCM DS methods
########################################

# DS device driver methods

def self.ncm_ds_device_driver_notes
  puts "check if the device drivers compiled correctly"
  puts "during DS startup, DS complies all the dasl files listed under custompackage, and package directories"
  puts "if device driver complilation failed, discovery of devices will also fail"
  puts "solutions: "
  puts "(a) if the driver compile failed due to 'Duplicate Variable Name' "
  puts "    you may have 2 dasl files with the same driver ID. remove duplicate dasl file"
  puts " "
end

def self.ncm_ds_device_driver_compile_status
  cmd="ssh root@#{$cdm} grep DASL::Compile: #{$ncm_voyence_home}/logs/autodisc.log |tail -n 1"
  output = `#{cmd}`
  puts `#{cmd}`
  if output =~ /Errors/
   puts "Device driver compilation failed. Devices cannot be discovered. Check autodisc.log file and fix the errors"
  else
   puts "Device driver compilation was a success"
  end
end

def self.ncm_check_device_drivers
  puts "each device driver must have a unique driver ID"
  f=File.new("/root/smangam/#{$cdm}_device_drivers.txt","w")
  cmd="ssh root@#{$cdm} 'find #{$ncm_voyence_home}/*package/ -name *.dasl -exec grep -i devicedriver {} \\; |cut -d#{$sqlesc})#{$sqlesc} -f1|cut -d#{$sqlesc}(#{$sqlesc} -f2|awk -F#{$sqlesc}:#{$sqlesc} #{$sqlesc}{print $2,$1}#{$sqlesc} |sed #{$sqlesc}s:^[ ^t]*::g#{$sqlesc}' "
  f.puts `#{cmd}`
  f.close

  device_driver_idx=`cat /root/smangam/#{$cdm}_device_drivers.txt |awk '{print $1}'`.chomp.split
  device_driver_idx.each {|x|
    cmd="ssh root@#{$cdm} 'find #{$ncm_voyence_home}/*package/ -name *dasl -exec grep :#{x}: {} \\;| grep -i devicedriver|wc -l' "
    count=`#{cmd}`.chomp.to_i
    if count > 1
      puts "device driver #{x} has #{count} dasl files. only one should exist"
      cmd="ssh root@#{$cdm} 'find #{$ncm_voyence_home}/*package/ -name *dasl -exec grep :#{x}: {} \\;| grep -i devicedriver' "
      puts `#{cmd}`
    end 
  }
end

########################################
# NCM device discovery methods
########################################

def self.ncm_autodisclogs
  print "enter the device ip address:"
  ip=gets.chomp
  cmd="ssh root@#{$cdm} grep #{ip} #{$ncm_voyence_home}/logs/autodisc*log"
  f=File.new("/root/smangam/#{$cdm}_autodisc.log","w")
  f.puts `#{cmd}`
  f.close
  puts "autodisc.log file written to /root/smangam/#{$cdm}_autodisc.log"
end

def self.ncm_autodisclogs_full
  cmd="ssh root@#{$cdm} cat #{$ncm_voyence_home}/logs/autodisc.log"
  f=File.new("/root/smangam/#{$cdm}_autodisc_full.log","w")
  f.puts `#{cmd}`
  f.close
  puts "autodisc.log file written to /root/smangam/#{$cdm}_autodisc_full.log"
end

def self.ncm_packageorder
  puts "the required device driver should be in the list of available drivers. if not add the appropriate driver from NCM app server"
  cmd="scp /root/smangam/smpackageorder.sh #{$cdm}:#{$ncm_voyence_home}/bin"
  system("#{cmd}")
  cmd="ssh root@#{$cdm} #{$ncm_voyence_home}/bin/smpackageorder.sh"
  output=`#{cmd}`
  puts output
end


###################################
# NCM InfraDB
###################################

# method to get AS InfraDB for all AS servers
def self.get_cflist
 $ncmappservers.each { |x|
   f=File.new("/root/smangam/#{x}_cflist.txt","w")
   cmd="ssh root@#{x} /opt/smarts-ncm/cgi-bin/smcflist.sh"
   output=`#{cmd}`
   f.puts output
   f.close
  }
end

# method to get DS InfraDB
def self.get_cflist_ds
  f=File.new("/root/smangam/smcflist_ds_#{$cdm}.sh","w")
  f.puts "source /etc/voyence.conf"
  f.puts "#{$ncm_voyence_home}/cgi-bin/cflist.cgi mode=pop"
  f.close

  cmd="chmod 777 /root/smangam/smcflist_ds_#{$cdm}.sh"
  `#{cmd}`

  cmd="scp /root/smangam/smcflist_ds_#{$cdm}.sh #{$cdm}:/tmp/"
  puts `#{cmd}`

  f2=File.new("/root/smangam/#{$cdm}_cflist.txt","w")
  cmd="ssh root@#{$cdm} /tmp/smcflist_ds_#{$cdm}.sh"
  output=`#{cmd}`
  f2.puts output
  f2.close
end

def self.print_cflist_ds
  get_cflist_ds
  f=File.new("/root/smangam/#{$cdm}_cflist.txt")
  f.each {|line| puts line}
  f.close
end

def self.ncm_list_obsolete_ds_in_infradb
  get_cflist
  printf("%30s %30s %20s %20s\n","appserver","CDM","POPID","ipaddress")
  $ncmappservers.each { |as|
    cmd=%Q?cat /root/smangam/#{as}_cflist.txt|grep '^POP'|awk '{print $3}'|sed s/\\"//g?
    ds_list=`#{cmd}`.chomp.split
    ds_list.each { |ds|
      if !host_exists?(ds) and !host_exists_in_dns?(ds)
        cmd=%Q?cat /root/smangam/#{as}_cflist.txt|grep '^POP'|awk '{print $2,$3}'|sed s/\\"//g|grep '?+ds+%Q?$'|awk '{print $1}'?
        pop=`#{cmd}`.chomp
        cmd=%Q?cat /root/smangam/#{as}_cflist.txt|grep '^POP'|awk '{print $9,$3}'|sed s/\\"//g|grep '?+ds+%Q?$'|awk '{print $1}'|cut -d'=' -f2|sed s/\\"//g?
        ipaddress=`#{cmd}`.chomp
        printf("%30s %30s %20s %20s\n",as,ds,pop,ipaddress)
      end 
    }
  }
end

# get popnumber for a given CDM in DS and AS InfraDB and ControlDB
def self.ncm_cdm_popnumber(cdm)
  get_cflist
  ncm_get_cdm_as_db_server(cdm)

  myCDM=cdm.upcase

  #pop id in AS Infradb
  #cmd="cat /root/smangam/#{$ncm_appserver}_cflist.txt|grep '^POP'|grep #{myCDM}|cut -d' ' -f2|wc -l"
  cmd=%Q?cat /root/smangam/#{$ncm_appserver}_cflist.txt|grep '^POP'|awk '{print $2,$3}'|sed s/\\"//g|grep '?+myCDM+%Q?$'|awk '{print $1}'|wc -l?
  count=`#{cmd}`.chomp.to_i
  if count > 1
    puts "ERROR!: #{cdm} exists #{count} times in the Infra database"
    cmd="grep #{myCDM} amcdlncmapp*cflist.txt"
    puts `#{cmd}`
  elsif count == 0
    puts "#{cdm} does not exist in the Infra database"
  elsif count == 1
    #cmd="cat /root/smangam/#{$ncm_appserver}_cflist.txt|grep '^POP'|grep #{myCDM}|cut -d' ' -f2"
    cmd=%Q?cat /root/smangam/#{$ncm_appserver}_cflist.txt|grep '^POP'|awk '{print $2,$3}'|sed s/\\"//g|grep '?+myCDM+%Q?$'|awk '{print $1}'?
    $cdm_popnumber_infradb=`#{cmd}`.chomp
    cmd=%Q?cat /root/smangam/#{$ncm_appserver}_cflist.txt|grep '^POP'|awk '{print $9,$3}'|sed s/\\"//g|grep '?+myCDM+%Q?$'|awk '{print $1}'|cut -d'=' -f2|sed s/\\"//g?
    #cmd="cat /root/smangam/#{$ncm_appserver}_cflist.txt|grep '^POP'|grep '"+myCDM+"$'|cut -d' ' -f9|cut -d'=' -f2"
    $infradb_ipaddress=`#{cmd}`.chomp
    puts "#{cdm} pop id in InfraDB is #{$cdm_popnumber_infradb} with #{$infradb_ipaddress}"
  end

  #pop id in the local(DS) Infradb
  get_cflist_ds
  cmd="cat /root/smangam/#{cdm}_cflist.txt|grep '^POP'|cut -d' ' -f2|wc -l" 
  count=`#{cmd}`.chomp.to_i
  if count > 1
    puts "ERROR!: #{cdm} exists #{count} times in the Local(DS) Infra database"
  elsif count == 0
    puts "#{cdm} does not exist in the Local(DS) Infra database"
  elsif count == 1
    cmd="cat /root/smangam/#{cdm}_cflist.txt|grep '^POP'|cut -d' ' -f2"
    $cdm_popnumber_ds_infradb=`#{cmd}`.chomp
    cmd="cat /root/smangam/#{cdm}_cflist.txt|grep '^POP'|cut -d' ' -f9|cut -d'=' -f2"
    $infradb_ds_ipaddress=`#{cmd}`.chomp
    puts "#{cdm} pop id in Local InfraDB is #{$cdm_popnumber_ds_infradb} with #{$infradb_ds_ipaddress}"
  end

  #pop id in controldb
  cmd="grep -i '"+myCDM+" ' /root/smangam/#{$ncm_dbserver}_device_servers.txt |wc -l"
  count=`#{cmd}`.to_i
  if count>1
    puts "#{cdm} exists #{count} times in the postgresql controldb database"
  elsif count == 0
    puts "#{cdm} does not exist in controldb"
  elsif count == 1
    cmd="cat #{$ncm_dbserver}_device_servers.txt|grep -i '"+cdm+" '|awk '{print $3}'"
    $cdm_popnumber_controldb=`#{cmd}`.chomp
    puts "#{cdm} pop id in ControlDB is: #{$cdm_popnumber_controldb}"
  end

  if $cdm_popnumber_controldb !=  $cdm_popnumber_ds_infradb || $cdm_popnumber_ds_infradb != $cdm_popnumber_infradb || $cdm_popnumber_controldb != $cdm_popnumber_infradb
    puts "ERROR! CDM popnumber is not consistent in DS,AS InfraDBs ,and ControlDB"
  else
    $popnumber = $cdm_popnumber_ds_infradb
  end
end

# method to check for duplicate IPs in infradb
def self.ncm_check_ip_infradb
  puts "checking for duplicate IP address entries for DS"
  print "enter DS IP address:"
  myip=gets.chomp
  cmd="cat /root/smangam/amcdlncmapp*_cflist.txt|grep '^POP'|grep ADDR="+'\"'+myip+'\"'+ "|wc -l"
  puts cmd
  count=`#{cmd}`.to_i
  if count > 1
    puts "ERROR!: IP address #{myip} is assigned to multiple Device Servers"
    cmd="cat /root/smangam/amcdlncmapp*_cflist.txt|grep '^POP'|grep ADDR="+'\"'+myip+'\"'
    puts `#{cmd}`
  elsif count == 1
    puts "No duplicate IP addresses found"
    cmd="cat /root/smangam/amcdlncmapp*_cflist.txt|grep '^POP'|grep ADDR="+'\"'+myip+'\"'
    puts `#{cmd}`
  elsif count == 0
    puts "No device server is assigned the IP address #{myip} in the InfraDB"
  end 
end

def self.ncm_check_infradb
  puts "checking if POP ID exists with empty/null Device Server"
  puts "this will cause NCM GUI to abort with 'Invalid IP Address' error in daemon.log"
  puts "if a null entry exists, remove from the HEAD NetList and POP row from the AS Infra DB"
  puts " "
  cmd="grep '\"\"' /root/smangam/amcdlncmapp*cflist.txt"
  #puts cmd
  puts `#{cmd}`
end

def self.ncm_get_ds_for_popid_infradb
  print "enter POP ID for a given DS:"
  mypopid=gets.chomp
  cmd="grep '^POP #{mypopid}' /root/smangam/amcdlncmapp*_cflist.txt"
  puts `#{cmd}`
end

def self.cleanup_infradb
 puts "(0) login to appserver. cd to /opt/smarts-ncm/cgi-bin"
 puts "    execute ./cflist.cgi > smtemp.txt"
 puts "(1) identify the pop number for the CDM in the controldb"
 puts "(2) modify the Infradb"
 puts "(2)(a) remove the duplicates from the Infradb. Keep the pop number that exists in the controldb"
 puts "(2)(b) copy the updated cflist file over to the NCM app server"
 puts "(3) update the Infradb"
 puts "(3)(a) stop vcmaster on the NCM app server: systemctl stop vcmaster"
 puts "(3)(b) source /etc/voyence.conf"
 puts "(3)(c) execute: /opt/smarts-ncm/cgi-bin/cfwrite.cgi < updatedcflist.txt"
 puts "(3)(d) start vcmaster: systemctl start vcmaster"
end

def self.cleanup_ds_infradb
 puts "(0) login to CDM. cd to /opt/smarts-ncm/cgi-bin"
 puts "    execute ./cflist.cgi mode=pop > smtemp.txt"
 puts "(1) identify the pop number for the CDM in the controldb"
 puts "(2) modify the Infradb"
 puts "(2)(a) remove the duplicates from the Infradb. Keep the pop number that exists in the controldb"
 puts "(2)(b) copy the updated cflist file over to the NCM app server"
 puts "(3) update the Infradb"
 puts "(3)(a) stop vcmaster on the NCM app server: systemctl stop vcmaster"
 puts "(3)(b) source /etc/voyence.conf"
 puts "(3)(c) execute: /opt/smarts-ncm/cgi-bin/cfwrite.cgi < updatedcflist.txt"
 puts "(3)(d) start vcmaster: systemctl start vcmaster"
end

def self.list_devices_for_ds_infradb
  puts "list of devices in InfraDB for pop nuumber #{$popnumber}"
  cmd="cat /root/smangam/#{$ncm_appserver}_cflist.txt|grep '^DEV'|grep PopParent=#{$popnumber}"
  puts "device data records:"
  puts `#{cmd}`
end

def self.get_device_from_infradb
  print "enter device name or idx:"
  $device=gets.chomp
  cmd=%Q-cat /root/smangam/#{$ncm_appserver}_cflist.txt|grep '^DEV'|grep \\"#{$device}\\"-
  puts "device data record:"
  puts `#{cmd}`
  cmd=%Q~cat /root/smangam/#{$ncm_appserver}_cflist.txt|grep '^DEV'|grep \\"#{$device}\\"|cut -d' ' -f2~
  $device_idx=`#{cmd}`.chomp
  puts "device IDX is #{$device_idx}"
end

def self.find_devices_in_infradb
  print "enter device sysobjectid:"
  sysobjectid=gets.chomp
  $ncmappservers.each { |x|
    cmd="grep #{sysobjectid} /root/smangam/#{x}_cflist.txt"
    output=`#{cmd}`
    puts output
  }
end

def self.get_device_info
  print "enter device name or idx:"
  $device=gets.chomp
  cmd="cat /root/smangam/#{$ncm_appserver}_cflist.txt|grep '^DEV'|grep #{$device}"
  puts "device data record:"
  puts `#{cmd}`
  cmd="cat /root/smangam/#{$ncm_appserver}_cflist.txt|grep '^DEV'|grep #{$device}|cut -d' ' -f2"
  $device_idx=`#{cmd}`.chomp
  puts "device IDX is #{$device_idx}"
end

def self.ncm_itsm_device_contract
  puts "each device should have the service property of configuration monitoring, in order for it to be monitored via NCM"
end

def self.ncm_gui_url
  puts "https://#{$ncm_appserver}:8880/voyence"
end

def self.ncm_gui_port
  cmd="ssh root@#{$ncm_appserver} netstat -anp|grep 8880"
end

##############################
# NCM ControlDB
##############################

def self.postgresql_simple_query
  print "enter sql query (commmon tables are cm_device_server,cm_device,cm_network):"
  sql=gets.chomp+";"
  cmd="ssh root@#{$ncm_dbserver} "+"'"+" #{$pgsql} -q -t -c " +'"'+sql+'"'+"'"
  puts `#{cmd}`
end

def self.ncm_controldb_list_active_queries
  sql='"'+"select procpid, usename, substring(current_query, 0, 99), waiting, query_start from pg_stat_activity where current_query IS DISTINCT FROM #{$sqlesc}<IDLE>#{$sqlesc};"+'"'
  cmd="ssh root@#{$ncm_dbserver} "+"'"+"#{$pgsql} -q -c " +sql+"'"
  puts `#{cmd}`
end


def self.ncm_get_device_servers_controldb
  $ncmdbservers.each { |x|
    sql='"'+"select device_server_name, device_server_idx as device_server_id from cm_device_server;" +'"'
    cmd="ssh root@#{x} "+"'"+" #{$pgsql} -q -t -c" +sql+"'"
    f=File.new("/root/smangam/#{x}_device_servers.txt","w")
    output=`#{cmd}`
    f.puts output
    f.close
    cmd="sed -i '/^$/d' /root/smangam/#{x}_device_servers.txt"
    `#{cmd}`
  }
end

def self.ncm_find_pop_in_controldb
 ncm_get_device_servers_controldb
 print "enter pop id:"
 mypopid=gets.chomp
 cmd="grep '"+mypopid+"' /root/smangam/amcalncmdb*txt"
 puts cmd
 puts `#{cmd}`
end

def self.ncm_find_cdm_in_controldb(cdm)
  ncm_get_device_servers_controldb
  # note that a DS may exist in multiple postgresql databases (for example, when a DS is moved to a new database, for load balancing)
  ds_upper=cdm.upcase

  cmd="grep '"+ds_upper+" ' /root/smangam/amcalncmdb*txt"
  puts cmd
  puts `#{cmd}`
end

def self.check_ds_duplicates_in_controldb
  $ncmdbservers.each { |x|
    sql='"'+"select count(*),device_server_name from cm_device_server group by device_server_name;" +'"'
    cmd="ssh root@#{x} "+"'"+" #{$pgsql} -q -t -c" +sql+"'"
    puts cmd
    f=File.new("/root/smangam/#{x}_device_servers_count.txt","w")
    output=`#{cmd}`
    f.puts output
    f.close
  }
  cmd="grep -v 1 amcalncmdb*_device_servers_count.txt|grep '|'"
  puts `#{cmd}`
end

def self.ncm_delete_ds_from_controldb
 print "enter DS(cdm) to check (example, am-goldcorp):"
 ds=gets.chomp.upcase
 puts "delete the device server from command line"
end

def self.get_device_list_from_controldb
  if $cdm == nil
    print "enter DS(cdm) (example, am-goldcorp):"
    ds=gets.chomp.upcase
  else
    ds=$CDM
  end
  ncm_get_cdm_as_db_server(ds)
  print "enter device search string (enter % for all devices):"
  device=gets.chomp
  sql='"'+"select a.device_name,a.device_idx,a.management_ip_address as ip_address,a.package_name,a.package_identifier as pkg_id,a.vendor_model,a.vendor_name as vendor from cm_device a,cm_network b where a.device_name like #{$sqlesc}%#{device}%#{$sqlesc} and a.primary_network_id=b.network_id and b.network_name=#{$sqlesc}#{ds}#{$sqlesc};"+'"'
  cmd="ssh root@#{$ncm_dbserver} "+"'"+"#{$pgsql} -q -c" +sql+"'"
  puts " "
  puts "cut thru mechanism codes: 0=snmp,2=telnet,3=ssh/scp,4=ssh/ftp,6=telnet/tftp"
  puts " "
  puts `#{cmd}`
  sql='"'+"select a.device_name,a.device_type,a.last_comm_attempt_time,a.last_comm_success_time,a.last_config_update_time,a.primary_mechanism as mechanism,b.network_name from cm_device a,cm_network b where a.device_name like #{$sqlesc}%#{device}%#{$sqlesc} and a.primary_network_id=b.network_id and b.network_name=#{$sqlesc}#{ds}#{$sqlesc} order by a.last_comm_attempt_time;"+'"'
  cmd="ssh root@#{$ncm_dbserver} "+"'"+"#{$pgsql} -q -c" +sql+"'"
  puts `#{cmd}`
end

def self.get_device_list2_from_controldb
  if $cdm == nil
    print "enter DS(cdm) (example, am-goldcorp):"
    ds=gets.chomp.upcase
  else
    ds=$CDM
  end
  ncm_get_cdm_as_db_server(ds)
  print "enter device search string (enter % for all devices):"
  device=gets.chomp
  sql='"'+"select a.device_name,a.device_idx,a.device_type,a.is_operational_device,encode(a.last_state_id,#{$sqlesc}hex#{$sqlesc}),a.cut_thru_mechanism from cm_device a,cm_network b where a.device_name like #{$sqlesc}%#{device}%#{$sqlesc} and a.primary_network_id=b.network_id and b.network_name=#{$sqlesc}#{ds}#{$sqlesc};"+'"'
  cmd="ssh root@#{$ncm_dbserver} "+"'"+"#{$pgsql} -q -c" +sql+"'"
  puts cmd
  puts " "
  puts "cut thru mechanism codes: 0=snmp,2=telnet,3=ssh/scp,4=ssh/ftp,6=telnet/tftp"
  puts " "
  puts `#{cmd}`
end

def self.get_device_pulldata_from_controldb
  if $cdm == nil
    print "enter DS(cdm) (example, am-goldcorp):"
    ds=gets.chomp.upcase
  else
    ds=$CDM
  end
  ncm_get_cdm_as_db_server(ds)
  print "enter device search string (enter % for all devices):"
  device=gets.chomp
  sql='"'+"select a.device_name,a.last_comm_attempt_time,a.last_comm_success_time,a.last_config_update_time,b.network_name from cm_device a,cm_network b where a.device_name like #{$sqlesc}%#{device}%#{$sqlesc} and a.primary_network_id=b.network_id and b.network_name=#{$sqlesc}#{ds}#{$sqlesc} order by a.last_comm_attempt_time;"+'"'
  cmd="ssh root@#{$ncm_dbserver} "+"'"+"#{$pgsql} -q -c" +sql+"'"
  puts `#{cmd}`
end

def self.list_networks_from_controldb
  sql='"'+"select encode(network_id,#{$sqlesc}hex#{$sqlesc}) as network_id,network_name from cm_network;"+'"'
  cmd="ssh root@#{$ncm_dbserver} "+"'"+"#{$pgsql} -q -c" +sql+"'"
  puts cmd
  puts `#{cmd}`
end

def self.get_network_from_controldb
  print "enter network id:"
  mynetwork_id=gets.chomp
  sql='"'+"select encode(network_id,#{$sqlesc}hex#{$sqlesc}) as network_id,network_name from cm_network where encode(network_id,#{$sqlesc}hex#{$sqlesc})=#{$sqlesc}#{mynetwork_id}#{$sqlesc};"+'"'
  cmd="ssh root@#{$ncm_dbserver} "+"'"+"#{$pgsql} -q -c" +sql+"'"
  puts cmd
  puts `#{cmd}`
end

def self.get_device_count_per_network_from_controldb
  $ncmdbservers.each {|x|
    f=File.new("/root/smangam/ncm_device_count_per_network_#{x}.txt","w")
    sql='"'+"select b.network_name, count(*) from cm_device a,cm_network b where a.primary_network_id=b.network_id group by b.network_name;"+'"'
    cmd="ssh root@#{x} "+"'"+"#{$pgsql} -t -q -c " +sql+"'"
    f.puts `#{cmd}`
    f.close
  }
end

def self.ncm_list_cdms_not_in_ncm
 get_device_count_per_network_from_controldb
 puts "the following CDMs do not exist in NCM..."
 f=File.open("/root/smangam/cdm_customers_all.txt")
 f.each {|line|
  x=line.chomp.upcase
  cmd="cat /root/smangam/ncm_device_count_per_network*.txt|awk '{print $1}'|grep ^#{x}$|wc -l"
  count=`#{cmd}`.chomp.to_i
  if count==0
   puts x
  end
 }
end

def self.get_job_status_from_controldb
  sql='"'+"select count(*), a.status, b.network_name from cm_job a, cm_network b where a.network_id=b.network_id and b.network_name like #{$sqlesc}%#{$CDM}%#{$sqlesc} group by a.status, b.network_name;"+'"'
  cmd="ssh root@#{$ncm_dbserver} "+"'"+"#{$pgsql} -q -c " +sql+"'"
  puts `#{cmd}`
end

def self.ncm_list_cdms_with_no_jobs
 puts "the following CDMs do not have config pulls for their devices"
 cmd="cat /root/smangam/amcalncmdb*device_servers.txt|awk '{print $1}'"
 cdm_list=`#{cmd}`.chomp.split

 cdm_list.each {|line|
  ds=line.chomp.upcase
  get_dbserver_for_ds(ds)
  if $ncm_dbserver!=nil 
    sql='"'+"select count(*) from cm_job a, cm_network b where a.network_id=b.network_id and b.network_name=#{$sqlesc}#{ds}#{$sqlesc};"+'"'
    cmd="ssh root@#{$ncm_dbserver} "+"'"+"#{$pgsql} -t -q -c " +sql+"'"
    count=`#{cmd}`.chomp.to_i
    if count==0
      puts "#{ds} does not have any config backups"
    end
  end
 }
end

def self.get_jobs_from_controldb
  print "enter job status(running,failed,canceled,complete):"
  mystatus=gets.chomp
  #sql='"'+"select job_name, a.status, b.network_name from cm_job a, cm_network b where a.status like #{$sqlesc}%#{mystatus}%#{$sqlesc} and a.network_id=b.network_id and b.network_name like #{$sqlesc}%#{$CDM}%#{$sqlesc};"+'"'
  sql='"'+"select job_name, job_number, job_status, job_target_time,task_status,task_number from cm_job_view where job_status like #{$sqlesc}%#{mystatus}%#{$sqlesc} and pri_network_name like #{$sqlesc}%#{$CDM}%#{$sqlesc};"+'"'
  cmd="ssh root@#{$ncm_dbserver} "+"'"+"#{$pgsql} -q -c " +sql+"'"
  puts `#{cmd}`
end

def self.get_running_jobs_from_controldb
  mystatus="running"
  #sql='"'+"select job_name, a.job_number, a.status, b.network_name from cm_job a, cm_network b where a.status like #{$sqlesc}%#{mystatus}%#{$sqlesc} and a.network_id=b.network_id and b.network_name like #{$sqlesc}%#{$CDM}%#{$sqlesc};"+'"'
  sql='"'+"select job_name, job_number, job_status, job_target_time,task_status,task_number from cm_job_view  where job_status like #{$sqlesc}%#{mystatus}%#{$sqlesc} and pri_network_name like #{$sqlesc}%#{$CDM}%#{$sqlesc};"+'"'
  cmd="ssh root@#{$ncm_dbserver} "+"'"+"#{$pgsql} -q -c " +sql+"'"
  puts `#{cmd}`
end

def self.get_running_jobs_from_controldb_all_cdms
  ncm_get_device_servers_controldb
  mystatus="running"
  printf("%20s %20s %20s\n","ncm_dbserver","cdm","total_running_jobs")
  $ncmdbservers.each { |ncm_dbserver|
    cmd="cat /root/smangam/#{ncm_dbserver}_device_servers.txt |awk '{print $1}'"
    cdm_list=`#{cmd}`.chomp.split
    cdm_list.each { |mycdm|
      #sql='"'+"select count(*) from cm_job a, cm_network b where a.status like #{$sqlesc}%#{mystatus}%#{$sqlesc} and a.network_id=b.network_id and b.network_name like #{$sqlesc}%#{mycdm}%#{$sqlesc};"+'"'
      sql='"'+"select count(*) from cm_job_view where job_status like #{$sqlesc}%#{mystatus}%#{$sqlesc} and pri_network_name like #{$sqlesc}%#{mycdm}%#{$sqlesc};"+'"'
      cmd="ssh root@#{ncm_dbserver} "+"'"+"#{$pgsql} -t -q -c " +sql+"'"
      count=`#{cmd}`.chomp
      if count.to_i > 0
        printf("%20s %20s %20s",ncm_dbserver,mycdm,count)
      end
    }
  }
end

def self.get_running_jobs_details_from_controldb_all_cdms
  ncm_get_device_servers_controldb
  mystatus="running"
  $ncmdbservers.each { |ncm_dbserver|
    puts "NCM DB Server: #{ncm_dbserver}"
    cmd="cat /root/smangam/#{ncm_dbserver}_device_servers.txt |awk '{print $1}'"
    cdm_list=`#{cmd}`.chomp.split
    cdm_list.each { |mycdm|
      sql='"'+"select count(*) from cm_job_view where job_status like #{$sqlesc}%#{mystatus}%#{$sqlesc} and pri_network_name like #{$sqlesc}%#{mycdm}%#{$sqlesc};"+'"'
      cmd="ssh root@#{ncm_dbserver} "+"'"+"#{$pgsql} -t -q -c " +sql+"'"
      count=`#{cmd}`.chomp
      if count.to_i > 0
        sql='"'+"select distinct format(#{$sqlesc}'#{$sqlesc}%-20s %-20s %-20s %-20s %-20s#{$sqlesc}'#{$sqlesc},pri_network_name,job_name,job_number,job_status,job_target_time) from cm_job_view where job_status like #{$sqlesc}%#{mystatus}%#{$sqlesc} and pri_network_name like #{$sqlesc}%#{mycdm}%#{$sqlesc};"+'"'
        cmd="ssh root@#{ncm_dbserver} "+"'"+"#{$pgsql} -t -q -c " +sql+"'"
        puts `#{cmd}`
      end
    }
  }
end

def self.get_stale_running_jobs_details_from_controldb_all_cdms
  ncm_get_device_servers_controldb
  mystatus="running"
  $ncmdbservers.each { |ncm_dbserver|
    cmd="cat /root/smangam/#{ncm_dbserver}_device_servers.txt |awk '{print $1}'"
    cdm_list=`#{cmd}`.chomp.split
    cdm_list.each { |mycdm|
      sql='"'+"select count(*) from cm_job_view where job_status like #{$sqlesc}%#{mystatus}%#{$sqlesc} and pri_network_name like #{$sqlesc}%#{mycdm}%#{$sqlesc};"+'"'
      cmd="ssh root@#{ncm_dbserver} "+"'"+"#{$pgsql} -t -q -c " +sql+"'"
      count=`#{cmd}`.chomp
      if count.to_i > 0
        sql='"'+"select distinct pri_network_name,job_name, job_number, job_status,job_target_time from cm_job_view where job_status like #{$sqlesc}%#{mystatus}%#{$sqlesc} and pri_network_name like #{$sqlesc}%#{mycdm}%#{$sqlesc} and date_part(#{$sqlesc}'#{$sqlesc}day#{$sqlesc}'#{$sqlesc},current_timestamp - job_target_time) > 2;"+'"'
        cmd="ssh root@#{ncm_dbserver} "+"'"+"#{$pgsql} -t -q -c " +sql+"'"
        puts `#{cmd}`
      end
    }
  }
end

def self.get_job_status2_from_controldb
  sql='"'+"select max(a.job_number),a.job_name,a.status,b.network_name from cm_job a, cm_network b where a.job_name like #{$sqlesc}%Weekly Config Pull%#{$sqlesc} and a.network_id=b.network_id and b.network_name like #{$sqlesc}%#{$CDM}%#{$sqlesc} group by a.job_name, a.status,b.network_name;"+'"'
  cmd="ssh root@#{$ncm_dbserver} "+"'"+"#{$pgsql} -q -c" +sql+"'"
  puts `#{cmd}`
end

def self.get_job_status_for_device_from_controldb
  print "enter device name:"
  mydevice=gets.chomp
  sql='"'+"select max(a.job_number) as max_job_id,a.name,a.task_status,a.job_name from cm_job_view a where a.name like #{$sqlesc}#{mydevice}#{$sqlesc} and task_type like #{$sqlesc}%pull%#{$sqlesc} and a.pri_network_name like #{$sqlesc}#{$CDM}#{$sqlesc}  group by a.name,a.task_status,a.job_name;"+'"'
  cmd="ssh root@#{$ncm_dbserver} "+"'"+"#{$pgsql} -q -c" +sql+"'"
  puts `#{cmd}`

 # each revision is given a device_state_id in the table cm_device_revisionable_state
 # the most recent revision state id is the field last_state_id in the table cm_device for a given device
 sql='"'+"select a.creation_time,a.is_complete,a.version from cm_device_revisionable_state a where encode(a.device_state_id,#{$sqlesc}hex#{$sqlesc}) = (select encode(b.last_state_id,#{$sqlesc}hex#{$sqlesc}) from cm_device b,cm_network c where b.device_name=#{$sqlesc}#{mydevice}#{$sqlesc} and b.primary_network_id=c.network_id and c.network_name=#{$sqlesc}#{$CDM}#{$sqlesc});"+'"'
 cmd="ssh root@#{$ncm_dbserver} "+"'"+"#{$pgsql} -q -c" +sql+"'"
 puts "is_complete code: t=true, f=false"
 puts `#{cmd}`
end

def self.most_recent_pull_details_for_device
  print "enter device name:"
  mydevice=gets.chomp
  sql='"'+"select a.pull_results from cm_device_revisionable_state a where encode(a.device_state_id,#{$sqlesc}hex#{$sqlesc}) = (select encode(b.last_state_id,#{$sqlesc}hex#{$sqlesc}) from cm_device b, cm_network c where b.device_name=#{$sqlesc}#{mydevice}#{$sqlesc} and b.primary_network_id=c.network_id and c.network_name=#{$sqlesc}#{$CDM}#{$sqlesc});"+'"'
  cmd="ssh root@#{$ncm_dbserver} "+"'"+"#{$pgsql} -q -c" +sql+"'"
  puts `#{cmd}`
end

def self.get_job_status_details_for_device_from_controldb
  #print "enter device name (enter % for all devices):"
  #mydevice=gets.chomp
  print "enter job number:"
  myjob=gets.chomp
  sql='"'+"select a.name,a.job_number,a.job_target_time,a.task_name,a.task_type,a.task_number,a.task_status from cm_job_view a where job_number=#{$sqlesc}#{myjob}#{$sqlesc};"+'"'
  cmd="ssh root@#{$ncm_dbserver} "+"'"+"#{$pgsql} -q -c" +sql+"'"
  puts `#{cmd}`
end

def self.get_job_result_for_device_from_controldb
  #print "enter device name (enter % for all devices):"
  #mydevice=gets.chomp
  print "enter job number:"
  myjob=gets.chomp
  print "enter task number:"
  mytask=gets.chomp
  sql='"'+"select a.name,a.task_result from cm_job_view a where a.job_number=#{$sqlesc}#{myjob}#{$sqlesc} and a.task_number=#{$sqlesc}#{mytask}#{$sqlesc} ;"+'"'
  cmd="ssh root@#{$ncm_dbserver} "+"'"+"#{$pgsql} -q -c" +sql+"'"
  puts `#{cmd}`
end

######################################
# Voyence Config Download Report
# mysql RIM database on amcalidm01 stores the mapping of CDM to NCM DB
######################################

# on amcalidm01, mysql database called RIM exists. in the table CDMsOnVoyence, the mapping of CDM to NCM DB server exists
#amcalidm01 ~]$ mysql -u root RIM -e "sql statement"

# the perl script exists on amrimsupp01
#/opt/rim/scripts
#perl config_download_report_sm.pl

def self.get_cdm_entry_from_CDMsOnVoyence
  mysql="/opt/ddam/mysql-5.7.13/bin/mysql"
  sql='"'+"select * from CDMsOnVoyence where network=#{$sqlesc}#{$CDM}#{$sqlesc};"+'"'
  cmd="ssh root@amcalidm01 "+"'"+mysql +" -Ns -u root -e " + sql +" RIM"+"'"
  puts `#{cmd}`
end

#####################################
# APM methods
#####################################

def self.get_classes_apm
   cmd = "ssh root@"+$cdm +" dmctl -s "+ $APMserver + " getc"
   output=`#{cmd}`
   puts output
end

def self.get_instances_apm
   print "enter the device type(Switch,Router,Host,Firewall,Node):"
   value = gets.chomp
   cmd = "ssh root@"+$cdm +" dmctl -s "+ $APMserver + " geti #{value}"
   output=`#{cmd}`
   puts output
end

def self.search_instances_apm
   print "enter the device search string:"
   value = gets.chomp
   cmd = "ssh root@"+$cdm +" dmctl -s "+ $APMserver + " geti |grep ^#{value}"
   output=`#{cmd}`
   puts output
end

def self.get_instance_properties_all_apm
   puts "common classes: Router,Switch, ICIM_NetworkAdapter, UnitaryComputerSystem"
   puts "use ICIM_UnitaryComputerSystem to cover all classes"
   print "enter the instance:"
   value = gets.chomp
   cmd = "ssh root@"+$cdm +" dmctl -s "+ $APMserver + " get  ICIM_UnitaryComputerSystem::#{value}"
   output=`#{cmd}`
   puts output
end

def self.get_instance_properties_apm
   print "enter device:"
   $device=gets.chomp
   properties=["Name","Description","Model","SystemObjectID"]
   cmd = "ssh root@"+$cdm +" dmctl -s "+ $APMserver + " get  ICIM_UnitaryComputerSystem::#{$device}::Name"
   $name=`#{cmd}`.chomp
   puts "Name: "+ $name
   cmd = "ssh root@"+$cdm +" dmctl -s "+ $APMserver + " get  ICIM_UnitaryComputerSystem::#{$device}::Description"
   $description=`#{cmd}`
   puts "Description: "+ $description
   cmd = "ssh root@"+$cdm +" dmctl -s "+ $APMserver + " get  ICIM_UnitaryComputerSystem::#{$device}::SNMPAddress"
   $snmpaddress=`#{cmd}`.chomp
   puts "SNMPAddress: "+ $snmpaddress
   cmd = "ssh root@"+$cdm +" dmctl -s "+ $APMserver + " get  ICIM_UnitaryComputerSystem::#{$device}::Model"
   $model=`#{cmd}`
   puts "Model: "+ $model
   cmd = "ssh root@"+$cdm +" dmctl -s "+ $APMserver + " get  ICIM_UnitaryComputerSystem::#{$device}::Vendor"
   $vendor=`#{cmd}`
   puts "Vendor: "+ $vendor
   cmd = "ssh root@"+$cdm +" dmctl -s "+ $APMserver + " get  ICIM_UnitaryComputerSystem::#{$device}::Type"
   $type=`#{cmd}`
   puts "Type: "+ $type
   cmd = "ssh root@"+$cdm +" dmctl -s "+ $APMserver + " get  ICIM_UnitaryComputerSystem::#{$device}::SystemObjectID"
   $sysobjectid=`#{cmd}`.chomp
   puts "Sysobjectid: "+ $sysobjectid
   cmd = "ssh root@"+$cdm +" dmctl -s "+ $APMserver + " get  ICIM_UnitaryComputerSystem::#{$device}::ReadCommunity"
   $readcommunity=`#{cmd}`.chomp
   puts "ReadCommunity: "+ $readcommunity
end

# APM Instrumentation methods

def self.apm_get_device_instrumentation_objects
   if $device != nil; puts "recent device was #{$device}"; end
   print "enter the device:"
   $device = gets.chomp
   cmd = "ssh root@"+$cdm +" dmctl -s "+ $APMserver + " geti ICIM_Instrumentation|grep #{$device}"
   output=`#{cmd}`
   puts output
end

def self.apm_get_instrumentation_object_details
   print "enter the instrumentation object:"
   instrumentation_object = gets.chomp
   cmd = "ssh root@"+$cdm +" dmctl -s "+ $APMserver + " get ICIM_Instrumentation::#{instrumentation_object}"
   output=`#{cmd}`
   puts output

   cmd = "ssh root@"+$cdm +" dmctl -s "+ $APMserver + " get ICIM_Instrumentation::#{instrumentation_object}|grep CreationClassName|awk '{print $3}'"
   $instrumentation_class=`#{cmd}`.chomp
   puts "instrumentation class is #{$instrumentation_class}"

   cmd = "ssh root@"+$cdm +" dmctl -s "+ $APMserver + " get #{$instrumentation_class}::#{instrumentation_object}"
   puts cmd
   output=`#{cmd}`
   puts output
end

def self.apm_instrumentation_classes_used_by_apg
  puts "the following are the instrumentation classes used by APG, in collecting data from APM"
  puts "Memory"
  puts "Memory_Performance"
  puts "Processor"
  puts "Processor_Performance"
  puts "FileSystem"
  puts "FileSystem_Performance"
  puts "Port"
  puts "Interface"
  puts "NetworkAdapter_Performance"
  puts " "
  puts "select one of the above:"
  $apg_instrumentation_class=gets.chomp
end

def self.apm_get_device_instrumentation_objects_for_class
   if $device != nil; puts "recent device was #{$device}"; end
   print "enter the device:"
   $device = gets.chomp
   
   if $apg_instrumentation_class != nil; puts "recently selected instrumentation class was #{$apg_instrumentation_class}"; end
   print "enter the instrumentation class:"
   $apg_instrumentation_class = gets.chomp
   cmd = "ssh root@"+$cdm +" dmctl -s "+ $APMserver + " geti #{$apg_instrumentation_class}|grep #{$device}"
   output=`#{cmd}`
   puts output
end

def self.apm_get_instrumentation_object_details_for_class
   print "enter the instrumentation object:"
   instrumentation_object = gets.chomp
   puts "instrumentation class is #{$apg_instrumentation_class}"

   cmd = "ssh root@"+$cdm +" dmctl -s "+ $APMserver + " get #{$apg_instrumentation_class}::#{instrumentation_object}"
   puts cmd
   output=`#{cmd}`
   puts output
end

def self.apm_device_oidinfo
  if $device != nil; puts "recent device was #{$device}"; end
  print "enter device name:"
  $device=gets.chomp
  print "enter the number of times to poll:"
  polls=gets.chomp
  cmd = "ssh root@"+$cdm +" dmctl -s "+ $APMserver + " get  ICIM_UnitaryComputerSystem::#{$device}::CreationClassName"
  puts cmd
  type=`#{cmd}`.chomp
  puts "device creation class name is #{type}"
  f=File.new("/root/smangam/myoidInfo.conf","a")
  f.puts "pollingInterval = 240"
  f.puts "snmpTimeout = 500"
  f.puts "#{type} #{$device} All"
  f.close
  cmd="scp /root/smangam/myoidInfo.conf #{$cdm}:/opt/InCharge9/SAM/smarts"
  puts `#{cmd}`
  cmd="ssh root@#{$cdm} sm_perl /opt/In*/IP/smarts/bin/sm_oidInfo.pl -s #{$APMserver} -i /opt/InCharge9/SAM/smarts/myoidInfo.conf -d -c -p #{polls}"
  puts "use admin/gsoa4ever to login"
  system("#{cmd}")
  cmd="rm -rf /root/smangam/myoidInfo.conf"
  `#{cmd}`

  puts "scp the output file"
  print "enter source file:"
  source=gets.chomp
  cmd="scp #{$cdm}:#{source} /root/smangam"
  system("#{cmd}")
end

def self.apm_show_oidinfo_file_with_filter
 cmd="ls -ltr *csv"
 puts `#{cmd}`
 print "enter file to open:"
 myfile=gets.chomp
 print "enter instrumentation class:"
 myvalue=gets.chomp
 cmd="cat #{myfile} |grep #{myvalue}"
 puts `#{cmd}`
end

def self.apm_show_oidinfo_file
 cmd="ls -ltr *csv"
 puts `#{cmd}`
 print "enter file to open:"
 myfile=gets.chomp
 cmd="cat #{myfile}"
 puts `#{cmd}`
end

# APM Interface methods

def self.if_snmp_apm
   if $device == nil
     get_instance_properties_apm
   end
   puts "Device #{$device} IP address is #{$snmpaddress}"
   puts "SNMP Community String is #{$readcommunity}"
   print "Enter ifdescr/ifadmin/ifoper/inoctets/outoctets:"
   oidstring=gets.chomp
   cmd = "ssh root@"+$cdm+ " snmpwalk -v2c -c " + $readcommunity + " " + $snmpaddress + " #{oidstring}"
   puts cmd
   output=`#{cmd}`
   puts output
end

def self.get_interface_instances_apm
   if $device == nil
     get_instance_properties_apm
   end
   puts "List of interfaces for Device #{$device} with IP address #{$snmpaddress}"
   cmd = "ssh root@"+$cdm +" dmctl -s "+ $APMserver + " geti ICIM_NetworkAdapter |grep #{$device}"
   puts cmd
   $interface_array=`#{cmd}`.split
   puts $interface_array
end

def self.apm_get_interface_properties
   #puts "common classes: Router,Switch, ICIM_NetworkAdapter, UnitaryComputerSystem"
   #puts "use ICIM_UnitaryComputerSystem to cover all classes"
   print "enter the interface:"
   value = gets.chomp
   cmd = "ssh root@"+$cdm +" dmctl -s "+ $APMserver + " get  ICIM_NetworkAdapter::#{value}"
   #cmd = "ssh root@"+$cdm +" dmctl -s "+ $APMserver + " geti|grep  #{value}"
   puts cmd
   output=`#{cmd}`
   puts output
end

def self.apm_get_interface_properties_for_all
  if $device == nil
    get_instance_properties_apm
  end
  cmd = "ssh root@"+$cdm +" dmctl -s "+ $APMserver + " geti ICIM_NetworkAdapter |grep #{$device}"
  puts cmd
  $interface_array=`#{cmd}`.split
  puts $interface_array
  $interface_array.each { |x| 
   cmd = "ssh root@"+$cdm +" dmctl -s "+ $APMserver + " get  ICIM_NetworkAdapter::#{x} |grep DisplayName"
   interface_display_name=`#{cmd}`.chomp.gsub(/\s+/,'')
   cmd = "ssh root@"+$cdm +" dmctl -s "+ $APMserver + " get  ICIM_NetworkAdapter::#{x} |grep ' Description'"
   interface_description=`#{cmd}`.chomp.gsub(/\s+/,'')
   cmd = "ssh root@"+$cdm +" dmctl -s "+ $APMserver + " get  ICIM_NetworkAdapter::#{x} |grep IsManaged"
   interface_ismanaged=`#{cmd}`.chomp.gsub(/\s+/,'')
   puts "#{interface_display_name} #{interface_description} #{interface_ismanaged}"
  }
end

def self.apm_maxspeed_help
    puts "edit the file /opt/InCharge9/IP/smarts/regional/conf/discover/RIM_ForcedMaxSpeed.conf"
    puts "the entries are in the format:"
    puts "NAME=IF-madmazaocbr1/512 MAXSPEED=1000000000"
    puts "MAXSPEED should be in bps"
    puts "1 kbps = 1000 bps"
    puts "1 mbps = 1000000 bps"
    puts "1 gbps = 1000000000 bps"
end

def self.apm_get_maxspeed_file
  cmd="scp root@#{$cdm}:/opt/InCharge9/IP/smarts/regional/conf/discovery/RIM_ForcedMaxSpeed.conf /root/smangam"
  if system("#{cmd}")
    puts "successfully pulled #{$cdm}:/opt/InCharge9/IP/smarts/regional/conf/discovery/RIM_ForcedMaxSpeed.conf"
  end
end

def self.apm_put_maxspeed_file
  cmd="ssh root@#{$cdm} cp -p /opt/InCharge9/IP/smarts/regional/conf/discovery/RIM_ForcedMaxSpeed.conf /opt/InCharge9/IP/smarts/regional/conf/discovery/RIM_ForcedMaxSpeed.conf.bkp"
  if system("#{cmd}")
    puts "successfully created a backup of the conf file"
  end

  cmd="scp /root/smangam/RIM_ForcedMaxSpeed.conf root@#{$cdm}:/opt/InCharge9/IP/smarts/regional/conf/discovery/RIM_ForcedMaxSpeed.conf"
  if system("#{cmd}")
    puts "successfully pushed RIM_ForcedMaxSpeed.conf"
  end
end


# APM device certification methods

def self.reload_oid_apm
   cmd = "ssh root@"+$cdm +" /opt/InCharge9/IP/smarts/bin/sm_tpmgr -s  "+ $APMserver + " --reloadoid"
   puts cmd
   output=`#{cmd}`
   puts output
end

def self.show_certification_apm
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

def self.apm_find_certification_for_sysobjectid_in_cdm
  print "enter device sysobjectid:"
  model=gets.chomp
  cmd="ssh root@#{$cdm} dmctl -s #{$APMserver} get ICF_TopologyManager::ICF-TopologyManager |grep #{model}|wc -l"
  puts cmd
  count=`#{cmd}`.chomp.to_i
  if count > 0 
   puts "certification for #{model} exists in #{$cdm}"
  else
   puts "certification for #{model} does not exist in #{$cdm}"
  end
end

def self.apm_find_certification_for_sysobjectid_in_all
  print "enter device sysobjectid:"
  model=gets.chomp
  File.open("/root/smangam/cdm_solo.txt").each { |x|
    mycdm=x.chomp
    cmd="ssh root@#{mycdm} dmctl -s #{$APMserver} get ICF_TopologyManager::ICF-TopologyManager |grep #{model}|wc -l"
    count=`#{cmd}`.chomp.to_i
    if count > 0 
     puts "certification for #{model} exists in #{mycdm}"
    end
  }
end

def self.find_certification_by_model_apm
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

def self.find_certification_by_model_all_apm
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

def self.pull_custom_oidfile_apm
  cmd="scp root@#{$cdm}:/opt/InCharge9/IP/smarts/regional/conf/discovery/oid2type_Field.conf /root/smangam/#{$cdm}_oid2type_Field.conf"
  if system("#{cmd}")
    puts "successfully pulled #{$cdm}:/opt/InCharge9/IP/smarts/regional/conf/discovery/oid2type_Field.conf"
  end
end

def self.validate_custom_oidfile_apm
  cmd="tail -n 50 /root/smangam/#{$cdm}_oid2type_Field.conf"
  puts `#{cmd}`
end

def self.push_custom_oidfile_apm
  cmd="ssh root@#{$cdm} cp -p /opt/InCharge9/IP/smarts/regional/conf/discovery/oid2type_Field.conf /opt/InCharge9/IP/smarts/regional/conf/discovery/oid2type_Field.conf.bkp"
  if system("#{cmd}")
    puts "successfully created a backup of the conf file"
  end

  cmd="scp /root/smangam/#{$cdm}_oid2type_Field.conf root@#{$cdm}:/opt/InCharge9/IP/smarts/regional/conf/discovery/oid2type_Field.conf"
  if system("#{cmd}")
    puts "successfully pushed oid2type_Field.conf"
  end
end

def self.create_stanza_apm
 f=File.new("/root/smangam/#{$cdm}_stub_tmp.txt","w")
 # $/ is the delimiter for gets
 $/="ZENDZ"
 puts "enter the device certification (end certification with ZENDZ):"
 cert = STDIN.gets
 f.puts cert
 f.close
 $/="\n"
 cmd="grep -v ZENDZ /root/smangam/#{$cdm}_stub_tmp.txt > /root/smangam/#{$cdm}_stub.txt"
 `#{cmd}`
end

def self.append_stanza_apm
 cmd="cat /root/smangam/#{$cdm}_stub.txt >> /root/smangam/#{$cdm}_oid2type_Field.conf"
 `#{cmd}`
end

def self.device_discovery_apm
  print "enter device name:"
  device=gets.chomp
  print "enter current device type(Node,Switch,Router,etc) for #{device}:"
  devtype=gets.chomp
  cmd="ssh root@#{$cdm} dmctl -s #{$APMserver} invoke ICF_TopologyManager::ICF-TopologyManager rediscover #{devtype}::#{device}"
  system("#{cmd}")
end

######################################
# CDM Build methods
######################################

### Base CDM methods

def self.get_base_cdm
  print "enter base cdm:"
  $basecdm=gets.chomp
  $cdm=$basecdm
  print "enter IP address:"
  $ipaddress=gets.chomp
end

def self.add_dns_entry_solo_help
  message=<<-HERE
   From Eng-Pool VDI, start DNS Manager (DNS server is 152.110.244.16)
   Expand HAUP-SVR-DC001 -> Expand Forward Lookup Zones
   Right click on us.gsoa.local click on New Host (A)
   Enter the hostname (#{$cdm})
   Enter the IP address of the internal interface (#{$ipaddress})
   Make sure Create associated pointer (PTR) record is checked and click Add Host
   For Base CDM or Solo CDM, add 1 entry: example am-cdmMulti3.us.gsoa.local
  HERE
  puts message
end

def self.add_dns_entry_tenant_help
  message=<<-HERE
   From Eng-Pool VDI, start DNS Manager (DNS server is 152.110.244.16)
   Expand HAUP-SVR-DC001 -> Expand Forward Lookup Zones
   Right click on us.gsoa.local click on New Host (A)
   Enter the hostname (#{$tenantcdm})
   Enter the IP address of the internal interface (#{$ipaddress})
   Make sure Create associated pointer (PTR) record is checked and click Add Host
   For Tenant CDM, add 2 entries: example  am-oisa.us.gsoa.local and am-oisa.am-cdmMulti3.us.gsoa.local
  HERE
  puts message
end

def self.build_VM_help
  message=<<-HERE
   Connect to a vCenter
   From CDM 941 Folder, right-click cdm941templateProduction, and select "Deploy virtual machine from this template"
   Name -> <cdm name>; Inventory location should be the folder where the VM should be created (exampele CDM941)
   For Host/Cluster, Select RIM-CLUSTER. Click Next.
   For Resource Pools, RIM-CLUSTER. Click Next.
   For Storage, Select VNX-LUN-4xxx-CDMy (select the datastore with the highest free space)
   For Guest Customization, choose Do Not Customize
   Click Finish

   Select the VM, right-click and choose Edit Settings.
   From Edit, set the memory, CPU, disk space, and network cards
   for Solo CDM, set memory = 4gb; CPU=2; Disk size=30GB; and enable hotplug
   for Base CDM, set memory = 12gb; CPU=4; Disk size=36GB; add a network card for each tenant, and enable hotplug
   the first NIC card should be powered on and connected. the rest should not be powered on or connected
  HERE
  puts message
end

def self.VM_networkcards_help
 message=<<-HERE
 Solo CDM has 2 network cards.
  1st NIC is assigned to CDM-240. On OS, this is assigned to the internal (152.x.x.x) IP address of the CDM
  2nd NIC is assigned to <cdmname>-cdm-<nnnn>. On OS, this is assigned to external (172.x.x.x) IP of the CDM
 Base CDM with Tenants has multiple network cards
  1st NIC is assigned to CDM-240. On OS, this is assigned to the internal (152.x.x.x) IP address of the base CDM
  2nd NIC is assigned to <tenant-cdmname>-cdm-<nnnn>. On OS, this is assigned to external (172.x.x.x) IP of the 1st tenant CDM
  3rd NIC is assigned to <tenant-cdmname>-cdm-<nnnn>. On OS, this is assigned to external (172.x.x.x) IP of the 2nd tenant CDM
 HERE
 puts message
end

def self.list_interface_names
  puts "the newly created interfaces have a state of DOWN and do not have IP address assigned"
  cmd="ssh root@#{$basecdm} ip a s"
  puts `#{cmd}`
end

def self.create_basecdm_yaml
  puts "create the file #{$hieradata_node_dir}/#{$basecdm}.us.gsoa.local.yaml"
  cmd="ls #{$hieradata_node_dir}/#{$basecdm}.us.gsoa.local.yaml"
  if !system("#{cmd}")
    cmd="cp #{$hieradata_node_dir}/am-cdmmulti9.us.gsoa.local.yaml #{$hieradata_node_dir}/#{$basecdm}.us.gsoa.local.yaml"
    puts cmd
    system("#{cmd}")
  end
end

def self.validate_basecdm_yaml
  cmd="cat #{$hieradata_node_dir}/#{$basecdm}*yaml"
  puts `#{cmd}`
end

def self.site_pp_stanza
  puts "add the following to /etc/puppet/manifests/site.pp"
  print "node \'#{$basecdm}.us.gsoa.local\' {
    class { 'general': stage => 'pre', }
  }"
end

def self.validate_basecdm_site_pp
  cmd="cp /etc/puppet/manifests/site.pp /root/smangam"
  system("#{cmd}")
  cmd="grep -n node /root/smangam/site.pp | grep -A1 #{$basecdm} | cut -d':' -f1"
  lines=`#{cmd}`.chomp.split
  if lines[1] == nil
    last_line=`cat /root/smangam/site.pp|wc -l`.chomp
    lines[1]=last_line
  end
  cmd="sed -n '#{lines[0]},#{lines[1]}p' /root/smangam/site.pp"
  puts `#{cmd}`
end

def self.basecdm_copy_modified_routes
  cmd="scp amcdmconfig03:/etc/puppet/environments/branches_RIM_9_4_1_0/regional/modules/amrimcdm-multi/files/RIM_clone_eth0_routes.pl #{$basecdm}:/opt/rim"
  if system("#{cmd}")
    puts "success: #{cmd}"
  else
    puts "fail: #{cmd}"
  end
end

def self.basecdm_copy_custom_apm_certifications
  cmd="scp amcdmconfig02:/etc/puppet/regional/modules/amrimcdm/files/oid2type_Field.conf #{$basecdm}:/opt/InCharge9/IP/smarts/regional/conf/discovery/oid2type_Field.conf"
  if system("#{cmd}")
    puts "success: #{cmd}"
  else
    puts "fail: #{cmd}"
  end
  cmd="scp amcdmconfig02:/etc/puppet/regional/modules/amrimcdm/files/tpmgr-param.conf #{$basecdm}:/opt/InCharge9/IP/smarts/regional/conf/discovery/tpmgr-param.conf"
  if system("#{cmd}")
    puts "success: #{cmd}"
  else
    puts "fail: #{cmd}"
  end
end

def self.basecdm_remove_ncf_files
  cmd="ssh root@#{$basecdm} ls /opt/InCharge9/SAM/smarts/global/conf/icoi/*ncf"
  puts cmd
  system("#{cmd}")
  if $?.exitstatus==0
    puts "ncf files exist"
    cmd="ssh root@#{$basecdm} rm -rf /opt/InCharge9/SAM/smarts/global/conf/icoi/*ncf"
    puts cmd
    system("#{cmd}")
    if $?.exitstatus==0
      puts "ncf files deleted"
    end
  else
   puts "ncf files do not exist"
  end
end

def self.basecdm_update_firewall_rules
  cmd="ssh root@#{$basecdm} firewall-cmd --zone=public --add-port=9080/tcp"
  puts `#{cmd}`
  cmd="ssh root@#{$basecdm} firewall-cmd --zone=public --add-port=9080/tcp --permanent"
  puts `#{cmd}`
  cmd="ssh root@#{$basecdm} firewall-cmd --new-zone=msuc --permanent"
  puts `#{cmd}`
  cmd="ssh root@#{$basecdm} firewall-cmd --reload"
  puts `#{cmd}`
  cmd="ssh root@#{$basecdm} firewall-cmd --zone=msuc --add-source=152.110.0.0/16 --permanent"
  puts `#{cmd}`
  cmd="ssh root@#{$basecdm} firewall-cmd --zone=msuc --add-masquerade --permanent"
  puts `#{cmd}`
  cmd="ssh root@#{$basecdm} firewall-cmd --reload"
  puts `#{cmd}`
end

def self.get_tenant
  print "enter base cdm:"
  $basecdm=gets.chomp
  print "enter tenant cdm:"
  $tenantcdm=gets.chomp
  $cdm=$tenantcdm
  $TENANTCDM=$tenantcdm.upcase
  $CDM=$TENANTCDM
end

def self.tenant_details
  f=File.new("/root/smangam/#{$tenantcdm}_details.txt","w")
  print "enter #{$tenantcdm} internal ip address (152.110.240.xx):"
  $tenant_int_ip=gets.chomp
  f.puts "tenant_int_ip #{$tenant_int_ip}"

  $tenant_int_mask="255.255.255.0"
  f.puts "tenant_int_mask #{$tenant_int_mask}"

  print "enter #{$tenantcdm} external ip address (172.18.xx.254):"
  $tenant_ext_ip=gets.chomp
  oct1,oct2,oct3,oct4 = $tenant_ext_ip.split('.')
  f.puts "tenant_ext_ip #{$tenant_ext_ip}"


  $tenant_ext_mask="255.255.255.128"
  f.puts "tenant_ext_mask #{$tenant_ext_mask}"

  print "enter #{$tenantcdm} external gateway address ( #{oct1}.#{oct2}.#{oct3}.129 ):"
  $tenant_ext_gateway=gets.chomp
  f.puts "tenant_ext_gateway #{$tenant_ext_gateway}"

  cmd=%Q?grep #{$basecdm} -A 30 /etc/puppet/manifests/site.pp|grep 'ncm_app_host ' |cut -d'"' -f2?
  puts "#{cmd}"
  puts "NCM app server for the base CDM is: "+`#{cmd}`.chomp
  print "enter #{$tenantcdm} NCM host (amcdlncmapp01/02/03/04):"
  $tenant_ncm_host=gets.chomp
  f.puts "tenant_ncm_host #{$tenant_ncm_host}"

  cmd=%Q?grep #{$basecdm} -A 30 /etc/puppet/manifests/site.pp|grep ncm_app_host_ip|cut -d'"' -f2?
  puts "#{cmd}"
  puts "NCM app server IP for the base CDM is: "+`#{cmd}`.chomp
  print "enter #{$tenantcdm} NCM host ip(152.110.242.30/31/32/33):"
  $tenant_ncm_host_ip=gets.chomp
  f.puts "tenant_ncm_host_ip #{$tenant_ncm_host_ip}"

  cmd=%Q?grep #{$basecdm} -A 30 /etc/puppet/manifests/site.pp|grep apg_db_host|cut -d'"' -f2?
  puts "#{cmd}"
  puts "APG db host for the base CDM is: "+`#{cmd}`.chomp
  print "enter #{$tenantcdm} APG database host (amcalapgdb01/02/03/04/05):"
  $tenant_apg_db_host=gets.chomp
  f.puts "tenant_apg_db_host #{$tenant_apg_db_host}"

  cmd=%Q?grep #{$basecdm} -A 30 /etc/puppet/manifests/site.pp|grep apg_backend_host|cut -d'"' -f2?
  puts "#{cmd}"
  puts "APG backend host for the base CDM is: "+`#{cmd}`.chomp
  print "enter #{$tenantcdm} APG backend host (amcalapgbkend01/02/03):"
  $tenant_apg_backend_host=gets.chomp
  f.puts "tenant_apg_backend_host #{$tenant_apg_backend_host}"

  cmd=%Q?grep #{$basecdm} -A 30 /etc/puppet/manifests/site.pp|grep apg_backend_port|cut -d"'" -f2?
  puts "#{cmd}"
  puts "APG backend port for the base CDM is: "+`#{cmd}`.chomp
  print "enter #{$tenantcdm} APG backend port (3500):"
  $tenant_apg_backend_port=gets.chomp
  f.puts "tenant_apg_backend_port #{$tenant_apg_backend_port}"

  puts "tenant details:"
  puts "tenant internal ip address: #{$tenant_int_ip}"
  puts "tenant internal ip mask   : #{$tenant_int_mask}"
  puts "tenant external ip address: #{$tenant_ext_ip}"
  puts "tenant external ip mask   : #{$tenant_ext_mask}"
  puts "tenant external gateway   : #{$tenant_ext_gateway}"
  puts "tenant ncm host and ip    : #{$tenant_ncm_host} #{$tenant_ncm_host_ip}"
  puts "tenant apg db host        : #{$tenant_apg_db_host}"
  puts "tenant apg bknd host/port : #{$tenant_apg_backend_host} #{$tenant_apg_backend_port}"
  f.close
end

def self.create_sitepp_stub
  print "enter customer index(1,2,n,etc):"
  cust_index=gets.chomp
  print "enter interface name(ens224, etc):"
  interface_name=gets.chomp

  puts "the following is the tenant stub"
  puts '      '+'"'+$tenantcdm+'" => {'
  puts '        '+  'customer_index     => '+cust_index+','
  puts '        '+  'interface_name     => "'+interface_name+'",'
  puts '        '+  'internal_ip        => "'+$tenant_int_ip+'",'
  puts '        '+  'internal_mask      => "'+$tenant_int_mask+'",'
  puts '        '+  'interface_ip       => "'+$tenant_ext_ip+'",'
  puts '        '+  'interface_mask     => "'+$tenant_ext_mask+'",'
  puts '        '+  'customer_gw        => "'+$tenant_ext_gateway+'",'
  puts '        '+  'include_esm        => false,'
  puts '        '+  'include_voip       => false,'
  puts '        '+  'include_sa         => false,'
  puts '        '+  'enable_topology_maps  => false,'
  puts '        '+  'include_apg        => true,'
  puts '        '+  'apg_portal_host    => "amcdlapgprtl01",'
  puts '        '+  'apg_backend_host   => "'+$tenant_apg_backend_host+'",'
  puts '        '+  'apg_db_host        => "'+$tenant_apg_db_host+'",'
  puts '        '+  'apg_backend_port   => "'+$tenant_apg_backend_port+'",'
  puts '        '+  'include_ncm        => true,'
  puts '        '+  'ncm_app_host       => "'+$tenant_ncm_host+'",'
  puts '        '+  'ncm_app_host_ip    => "'+$tenant_ncm_host_ip+'",'
  puts '        '+  'calsam_index       => dep,'
  puts '        '+  'ensure             => "present",'
  puts '      },'
end

def self.get_interface_names
  puts "the newly created interfaces have a state of DOWN and do not have IP address assigned"
  cmd="ssh root@#{$basecdm} ip a s"
  puts `#{cmd}`
end

def self.where_cdm_is_deployed
  print "enter CDM:"
  mycdm=gets.chomp
  cmd="grep -i -A2 #{mycdm} #{$hieradata_node_dir}/amcalsam*yaml"
  puts cmd
  puts `#{cmd}`
end

def self.copy_snmp_collector
  cmd="ssh root@#{$basecdm} cp /opt/APG/Collecting/SNMP-Collector/#{$tenantcdm}/conf/snmp-polling-distribution-empty.xml /opt/APG/Collecting/SNMP-Collector/#{$tenantcdm}/conf/snmp-polling-distribution.xml"
  system("#{cmd}")
  if $?.exitstatus==0
    puts "snmp-polling-distribution.xml copy successful"
  else
   puts "snmp-polling-distribution.xml copy failed"
  end
  cmd="ssh root@#{$tenantcdm} /opt/rim/scripts/install-custom-apg-snmpC-MultiT.sh"
  puts cmd
  system("#{cmd}")
  if $?.exitstatus==0
    puts "snmp config successful"
    cmd="ssh root@#{$basecdm} ls -ltr /var/log/custom-snmpC-install.log"
    output=`#{cmd}`
    puts output
    cmd="ssh root@#{$basecdm} cat /var/log/custom-snmpC-install.log"
    output=`#{cmd}`
    puts output
  else
   puts "snmp config failed"
  end
end


######################################
# Delete CDM methods
######################################

def self.remove_puppet_cert
 cmd="puppet cert clean #{$cdm}.us.gsoa.local"
 puts `#{cmd}`
end

def self.sm_service_stop(mycdm)
  cmd="ssh root@#{mycdm} sm_service stop --all"
  puts cmd
  output=`#{cmd}`
  puts output
end

def self.sm_service_remove(mycdm)
  cmd="ssh root@#{mycdm} sm_service show"
  output=`#{cmd}`
  puts output
  puts "remove all services"
  puts "enter service to remove:"
  myservice=gets.chomp
  cmd="ssh root@#{mycdm} sm_service remove #{myservice}"
  output=`#{cmd}`
  puts output
end

def self.apg_stop
  cmd="ssh root@#{$cdm} /opt/APG/bin/manage-modules.sh service stop all"
  puts cmd
  output=`#{cmd}`
  puts output
end

def self.ncm_stop
  cmd="ssh root@#{$cdm} systemctl stop sysadmin.service"
  puts cmd
  output=`#{cmd}`
  puts output

  cmd="ssh root@#{$cdm} systemctl stop vcmaster.service"
  puts cmd
  output=`#{cmd}`
  puts output
end

def self.crond_stop
  cmd="ssh root@#{$cdm} systemctl stop crond.service"
  puts cmd
  puts `#{cmd}`
end

def self.hyperic_agent_stop
  cmd="ssh root@#{$cdm} systemctl stop hyperic-agent.service"
  puts cmd
  puts `#{cmd}`
end

# Tenant delete - steps on base CDM

def self.tenant_sm_service_stop
  cmd="ssh root@#{$basecdm} sm_service show"
  output=`#{cmd}`
  puts output
  puts "enter service to stop:"
  myservice=gets.chomp
  cmd="ssh root@#{$basecdm} sm_service stop #{myservice}"
  output=`#{cmd}`
  puts output
end

def self.tenant_sm_service_remove
  cmd="ssh root@#{$basecdm} sm_service show"
  output=`#{cmd}`
  puts output
  puts "enter service to remove:"
  myservice=gets.chomp
  cmd="ssh root@#{$basecdm} sm_service remove #{myservice}"
  output=`#{cmd}`
  puts output
end

def self.remove_tenant_apg_modules
  cmd="ssh root@#{$basecdm} manage-modules.sh list installed|grep #{$tenantcdm}|awk '{print $3}'"
  mod_list=`#{cmd}`.split
  f=File.new("/root/smangam/smtemp.sh","w")
  f.puts "#!/bin/sh"
  f.close
  mod_list.each {|x|
    cmd="ssh root@#{$basecdm} manage-modules.sh remove #{x} #{$tenantcdm}"
    f=File.new("/root/smangam/smtemp.sh","a")
    f.puts cmd
    f.close
  }
  print "exit the program, and execute smtemp.sh from the command line"
end

def self.remove_tenant_ncm_dir
  cmd="ssh root@#{$basecdm} rm -rf /opt/smarts-ncm-#{$tenantcdm}"
  puts cmd
  puts `#{cmd}`
end

def self.remove_tenant_smarts_dir
  cmd="ssh root@#{$basecdm} rm -rf /opt/InCharge9/SAM/smarts/customer/#{$tenantcdm}"
  puts cmd
  puts `#{cmd}`
  cmd="ssh root@#{$basecdm} rm -rf /opt/InCharge9/IP/smarts/customer/#{$tenantcdm}"
  puts cmd
  puts `#{cmd}`
  cmd="ssh root@#{$basecdm} rm -rf /var/opt/rim/#{$tenantcdm}"
  puts cmd
  puts `#{cmd}`
end

#########################################
# APG methods
#########################################

#mysql -s option is for silent output. boxes around the output are supressed
#mysql -N use this option to skip column names

$mysql="/opt/APG/Databases/MySQL/Default/bin/mysql"
$sqlesc="\'\"\'\"\'"
$prtlhost="amcdlapgprtl01"
$db_hash={}
# $dbhost_array 

# this method should be only called from host_exists?()
def self.apg_std_dirs(cdm)
 $apg_cdm_base_dir="/opt/APG/Collecting"

 # set collector conf dir
 if $cdm_type=="multi"
   $apg_collector_conf_dir = "/opt/APG/Collecting/Collector-Manager/#{cdm}/conf"
 elsif $cdm_type=="solo"
   $apg_collector_conf_dir = "/opt/APG/Collecting/Collector-Manager/Default/conf"
 end

 # set failover-filter config path
 cmd=%Q? ssh root@#{cdm} cat #{$apg_collector_conf_dir}/collecting.xml|grep -i 'name=\"FailOver-Backend\"'|awk '{print $5}'|cut -d= -f2|sed s/\\"//g ?
 if file_exists?(cdm,"#{$apg_collector_conf_dir}/collecting.xml")
   failover_config_file_string=`#{cmd}`.chomp
   if failover_config_file_string != nil
     apg_cdm_failover_config_file=$apg_cdm_base_dir+"/"+`#{cmd}`.chomp
     apg_cdm_failover_base_dir,y=apg_cdm_failover_config_file.split('conf')
     cmd=%Q? ssh root@#{cdm} cat #{apg_cdm_failover_config_file}|grep \\<temporary-storage|awk '{print $2}'|cut -d= -f2|sed s/\\"//g ?
     $apg_cdm_failover_storage_dir=apg_cdm_failover_base_dir+`#{cmd}`.chomp
   else
     $apg_cdm_failover_storage_dir=nil
     puts "#{cdm} does not have failover filter defined"
   end
 end
end

def self.apg_service_status
  print "enter hostname:"
  myhost=gets.chomp
  cmd = "ssh root@#{myhost} /opt/APG/bin/manage-modules.sh service status all"
  puts `#{cmd}`
end

def self.apg_service_manage
  print "enter hostname:"
  myhost=gets.chomp
  print "enter APG module to start or stop:"
  mymod=gets.chomp
  print "enter start,stop,status:"
  status=gets.chomp
  cmd = "ssh root@#{myhost} /opt/APG/bin/manage-modules.sh service #{status} #{mymod}"
  puts cmd
  puts `#{cmd}`
end

# APG DB methods

def self.get_dblist_apg
  # get the dbhosts from server.xml file
  cmd="cat /opt/APG/Web-Servers/Tomcat/Default/conf/server.xml|grep 'Resource name=' -A 5|grep APG -A 5|grep url|awk '{print $3}'|cut -f3 -d'/'|cut -f1 -d':'"
  $dbhost_array = `ssh root@#{$prtlhost} #{cmd}`.chomp.split
 
  # get the db from server.xml file
  cmd="cat /opt/APG/Web-Servers/Tomcat/Default/conf/server.xml|grep 'Resource name=' -A 5|grep APG -A 5|grep url|awk '{print $3}'|cut -f4 -d'/'|cut -f1 -d'?'"
  $db_array = `ssh root@#{$prtlhost} #{cmd}`.chomp.split
  
  # build a hash with db and dbhost
  (0..$dbhost_array.size-1).each do |i|
    $db_hash[$dbhost_array[i]] = $db_array[i]
  end
end

def self.get_db_cdm_list_apg
  sql='"'+"select distinct custtag from data_property_flat where vstatus=#{$sqlesc}active#{$sqlesc} or vstatus is NULL;"+'"'

  $dbhost_array.each { |x|
    a=x.chomp
    mydb=$db_hash[a].chomp
    f=File.new("/root/smangam/#{a}","w")
    cmd="ssh root@#{x} "+"'"+$mysql +" -Ns -h #{x} -u apg -e " + sql +" #{mydb}"+"'"
    cdmapg=`#{cmd}`.chomp
    f.puts cdmapg
    f.close
  }
  
  cmd="cat /root/smangam/amcalapgdb* |grep -v NULL > /root/smangam/apg_cdm_list.txt"
  puts `#{cmd}`
end

def self.exec_sql
  if $apg_cdm_dbhost == nil
    print "enter Database host:"
    $apg_cdm_dbhost=gets.chomp
  else
    puts "db host is #{$apg_cdm_dbhost}"
  end
  if $apg_cdm_db == nil
    print "enter database:"
    $apg_cdm_db=gets.chomp
  else
    puts "database is #{$apg_cdm_db}"
  end

  puts 'for single quotes, use #{$sqlesc}'
  print "enter sql statement:"
  sqlstmt=gets.chomp

  sql='"' + "#{sqlstmt};" +'"'
  cmd="ssh root@#{$apg_cdm_dbhost} "+"'"+" #{$mysql} --column-names -h #{$apg_cdm_dbhost} -u apg -e " +sql+" #{$apg_cdm_db} -t"+"'"
  puts cmd
  puts `#{cmd}`
end

def self.get_databases_on_dbhost
  if $apg_cdm_dbhost == nil
    print "enter db host:"
    $apg_cdm_dbhost=gets.chomp
  else
    puts "db host is #{$apg_cdm_dbhost}"
  end
  if $apgdb == nil; $apgdb='master';end

  sql='"' + "show databases;" +'"'
  cmd="ssh root@#{$apg_cdm_dbhost} "+"'"+" #{$mysql} --column-names -h #{$apg_cdm_dbhost} -u apg -e " +sql+" #{$apgdb} -t"+"'"
  output = `#{cmd}`
  puts output
end   

def self.get_db_size
  if $apg_cdm_dbhost == nil
    print "enter db host:"
    $apg_cdm_dbhost=gets.chomp
  else
    puts "db host is #{$apg_cdm_dbhost}"
  end
  if $apgdb == nil; $apgdb='master';end

  sql='"' + "select table_schema #{$sqlesc}db name#{$sqlesc}, round(sum(data_length + index_length)/1024/1024/1024,1) #{$sqlesc}db size in gb#{$sqlesc} from information_schema.tables group by table_schema;" +'"'
  cmd="ssh root@#{$apg_cdm_dbhost} "+"'"+" #{$mysql} --column-names -h #{$apg_cdm_dbhost} -u apg -e " +sql+" #{$apgdb} -t"+"'"
  output = `#{cmd}`
  puts output
end
  
def self.get_dbserver_processlist
  if $apg_cdm_dbhost == nil
    print "enter db host:"
    $apg_cdm_dbhost=gets.chomp
  else
    puts "db host is #{$apg_cdm_dbhost}"
  end
  if $apgdb == nil; $apgdb='master';end
  
  puts "processlist shows list of running threads across all the databases on  a db server"

  #sql='"' + "show status like #{$sqlesc}Threads#{$sqlesc};" +'"'
  sql='"' + "show processlist;" +'"'
  cmd="ssh root@#{$apg_cdm_dbhost} "+"'"+" #{$mysql} --column-names -h #{$apg_cdm_dbhost} -u apg -e " +sql+" #{$apgdb} -t"+"'"
  output = `#{cmd}`
  puts output
end

def self.get_dbserver_processlist_load_all
  puts "list of processes running LOAD DATA.."

  $dbhost_array.each do |x|
    sql='"' + "select * from information_schema.processlist where db !=#{$sqlesc}master#{$sqlesc} and info like #{$sqlesc}%LOAD%#{$sqlesc};" +'"'
    cmd="ssh root@#{x} "+"'"+" #{$mysql} --column-names -h #{x} -u apg -e " +sql+" master -t"+"'"
    puts "on Database server #{x}"
    puts `#{cmd}`
   end
end

def self.apg_get_devtypes
 sql='"'+ "select distinct devtype from data_property_flat where custtag=\'\"\'\"\'#{$CDM}\'\"\'\"\' ;"+'"'
 cmd="ssh root@#{$apg_cdm_dbhost} "+"'"+$mysql +" -Ns -h #{$apg_cdm_dbhost} -u apg -e " +sql+" #{$apgdb}"+"'"
 output = `#{cmd}`
 puts output
end

def self.apg_get_devices_by_devtype
  print "Please enter the devtype:"
  $devtype = gets.chomp
  sql='"' + "select distinct device, devtype,left(devdesc,30),model,ip from data_property_flat where custtag=#{$sqlesc}#{$CDM}#{$sqlesc} and devtype=#{$sqlesc}#{$devtype}#{$sqlesc} order by device;" +'"'
  cmd="ssh root@#{$apg_cdm_dbhost} "+"'"+" #{$mysql} --column-names -h #{$apg_cdm_dbhost} -u apg -e " +sql+" #{$apgdb} -t"+"'"
  output = `#{cmd}`
  puts output
end

def self.apg_get_devices_by_string
  print "Please enter the device search string:"
  $devstr = gets.chomp
  sql='"' + "select distinct device, devtype,left(devdesc,30),model,ip from data_property_flat where custtag=#{$sqlesc}#{$CDM}#{$sqlesc} and device like #{$sqlesc}%#{$devstr}%#{$sqlesc} order by device;" +'"'
  cmd="ssh root@#{$apg_cdm_dbhost} "+"'"+" #{$mysql} --column-names -h #{$apg_cdm_dbhost} -u apg -e " +sql+" #{$apgdb} -t"+"'"
  output = `#{cmd}`
  puts output
end

def self.apg_get_parttypes_for_a_device
  print "Please enter the device:"
  $apg_device = gets.chomp
  sql='"' + "select distinct parttype from data_property_flat where custtag=#{$sqlesc}#{$CDM}#{$sqlesc} and device= #{$sqlesc}#{$apg_device}#{$sqlesc} order by parttype;" +'"'
  cmd="ssh root@#{$apg_cdm_dbhost} "+"'"+" #{$mysql} --column-names -h #{$apg_cdm_dbhost} -u apg -e " +sql+" #{$apgdb} -t"+"'"
  output = `#{cmd}`
  puts output
end

##############################
# APG Backend methods
##############################

def self.apg_list_backends
  f=File.new("/root/smangam/apg_backend_list","w")
  File.open("/root/smangam/apg_cdm_list.txt").each { |a|
    x=a.chomp.downcase
    if host_exists?(x)
      apg_cdm_backend(x)
      f.puts "#{x} #{$apg_cdm_backend_host} #{$apg_cdm_backend_port}"
    end
  }
  f.close
end

def self.apg_backend_instances(backend_host)
  #get the backends
  cmd="ssh root@#{backend_host} ls /opt/APG/Backends/APG-Backend"
  output=`#{cmd}`.chomp
  backends = output.split(" ")

  backends.each do |backend|
    cmd="ssh root@#{backend_host} cat /opt/APG/Backends/APG-Backend/#{backend}/conf/socketinterface.xml|grep listen|cut -d'>' -f2|cut -d'<' -f1"
    myport=`#{cmd}`.chomp
    puts "Backend instance on #{backend_host}: #{backend}. The listening port is #{myport}"
  end
end

def self.apg_cdms_on_backend(backend_host)
  printf("%20s %-25s %-15s %-20s %-20s\n","cdm","backend_host","backend_port","/opt-used%","/opt-freeMB")
  File.open("/root/smangam/apg_cdm_list.txt").each { |a|
    x=a.chomp.downcase
    if host_exists?(x)
      host_env(x)
      apg_cdm_backend(x)
      if $apg_cdm_backend_host==backend_host
        printf("%20s %-25s %-15s %-20s %-20s\n",x,$apg_cdm_backend_host,$apg_cdm_backend_port,$cdm_opt_usedpercent,$cdm_opt_freemb)
      end
    end
  }
end

def self.apg_backend_mysql_info(backend_host)
  #get the backends
  cmd="ssh root@#{backend_host} ls /opt/APG/Backends/APG-Backend"
  output=`#{cmd}`.chomp
  backends = output.split(" ")

  backends.each do |backend|
    cmd="ssh root@#{backend_host} cat /opt/APG/Backends/APG-Backend/#{backend}/conf/mysql.xml|grep 'connection url'"
    mydata=`#{cmd}`.chomp
    puts "Backend instance on #{backend_host}: #{backend}. MySQL database destination is #{mydata}"
  end
end

def self.backend_tmpdir_status(backend_host)
  #get the backends
  cmd="ssh root@#{backend_host} ls /opt/APG/Backends/APG-Backend"
  output=`#{cmd}`.chomp
  backends = output.split(" ")

  #get the tmp dir name
  backends.each do |backend|
    puts "Backend instance on #{backend_host}: #{backend}"
    cmd="ssh root@#{backend_host} cat /opt/APG/Backends/APG-Backend/#{backend}/conf/config.xml|grep temporary-files|grep -v '<!--'|awk '{print $3}'|cut -f2 -d'>'|cut -f1 -d'<'"
    tmpdir=`#{cmd}`.chomp
    cmd="ssh root@#{backend_host} ls -ltr /opt/APG/Backends/APG-Backend/#{backend}/#{tmpdir} | grep -v total |wc -l 2>/dev/null"
    tmpdir_files=`#{cmd}`.chomp
    if ( tmpdir_files.to_i > 80) then
        puts "Total tmp files is #{tmpdir_files}. Recommended to restart backend service"
    else
      puts "Total tmp files is #{tmpdir_files}"
    end
  end
  cmd="ssh root@#{backend_host} df -m"
  puts `#{cmd}`
end

def self.backend_socket_connections(backend_host)
  puts "data transfer of inQDumpFilennn.qdf files from CDM occurs only if a TCP connection exists between the CDM and Backend port"
  puts "if you do not see active connections, there may be a problem with the Backend"
  print "enter #{backend_host} backend listening port number:"
  myport=gets.chomp
  cmd="ssh root@#{backend_host} netstat -anp|grep '"+myport+" '"
  puts cmd
  puts `#{cmd}`
end

###########################
# APG CDM methods
###########################

def self.apg_cdm_backend(cdm)
  if file_exists?(cdm,"#{$apg_collector_conf_dir}/backend-socketconnector.xml")
    cmd = "ssh root@#{cdm} cat #{$apg_collector_conf_dir}/backend-socketconnector.xml|grep '<host>'|cut -d '>' -f2|cut -d'<' -f1"
    $apg_cdm_backend_host = `#{cmd}`.chomp
    cmd = "ssh root@#{cdm} cat #{$apg_collector_conf_dir}/backend-socketconnector.xml|grep '<port>'|cut -d '>' -f2|cut -d'<' -f1"
    $apg_cdm_backend_port = `#{cmd}`.chomp
  end
end

def self.apg_move_files
 print "enter file(with full path) to move (example /opt/APG/Collecting/FailOver-Filter/Default/tmp-backend/inQ*):"
 file_from=gets.chomp
 print "enter dir where you want the file(s) to be moved(example /tmp):"
 file_to=gets.chomp
 cmd="ssh root@#{$cdm} mv #{file_from} #{file_to}"
 puts cmd
 puts `#{cmd}`
end

def self.apg_list_files
  print "enter dir to list files (/tmp or /tmp/inQDumpFile* for example):"
  mydir=gets.chomp
  cmd="ssh root@#{$cdm} ls #{mydir}"
  puts cmd
  puts `#{cmd}`
end

def self.apg_fs_status_all
  File.open("/root/smangam/apg_cdm_list.txt").each { |a|
   x=a.chomp
   if host_exists?(x) 
     cmd = "ssh root@"+x +" df -m|grep opt | grep -v Filesystem|awk '{print $5,$4/1024,$6}'|sed 's/%//g' | awk '{if ($1 > 99) print $3,$2,$1}'"
     output = `#{cmd}`.chomp
     if !output.empty?
      puts "DISK USAGE for #{x} is: " + output +"%"
     end
   end
 }
end


# APG CDM Failover filter methods

def self.apg_cdm_failover_filter_status
  if $apg_cdm_failover_storage_dir!=nil
    puts "the count of files in #{$apg_cdm_failover_storage_dir} should be <10"
    cmd = "ssh root@#{$cdm} ls -ltr #{$apg_cdm_failover_storage_dir}"
    puts cmd
    puts `#{cmd}`
    cmd = "ssh root@#{$cdm} ls -ltr #{$apg_cdm_failover_storage_dir}|grep qdf|wc -l"
    puts "Total files waiting to move to Backend: "+`#{cmd}`.chomp
  end
end

def self.apg_cdm_failover_filter_qdf_count(cdm)
  if file_exists?(cdm,"#{$apg_cdm_failover_storage_dir}/*qdf")
    cmd = "ssh root@#{cdm} ls -ltr #{$apg_cdm_failover_storage_dir}/*qdf|wc -l"
    `#{cmd}`.chomp.to_i
  else
    return 0
  end
end

def self.apg_cdm_failover_filter_status_all
  puts "the list of files in /opt/APG/Collecting/FailOver-Filter/ are pending to move to the Backend"
  printf("%20s %-10s %-15s %-15s %-15s %-20s %-15s %-15s %-8s\n","cdm","qdf-count","/opt-freeMB","/opt-%used","/-freeMB","backend_host","backend_port","dbhost","db")
  File.open("/root/smangam/apg_cdm_list.txt").each { |a|
    x=a.chomp.downcase
    if host_exists?(x)
      host_env(x)
      if $apg_cdm_failover_storage_dir!=nil
        cmd = "ssh root@#{x} ls -ltr #{$apg_cdm_failover_storage_dir}/|grep qdf|wc -l"
        count= `#{cmd}`.chomp
        if count.to_i >1
          printf("%20s %-10s %-15s %-15s %-15s %-20s %-15s %-15s %-8s\n",x,count,$cdm_opt_freemb,$cdm_opt_usedpercent,$cdm_root_freemb,$apg_cdm_backend_host,$apg_cdm_backend_port,$apg_cdm_dbhost,$apg_cdm_db)
        end
      end
    end
    }
end
   
def self.apg_manage_qdf_files(cdm)
  cmd = "ssh root@#{cdm} ls -ltr #{$apg_cdm_failover_storage_dir}/*qdf|wc -l"
  qdf_count=`#{cmd}`.chomp.to_i

  cmd = "ssh root@#{cdm} ls -ltr /tmp|grep qdf|wc -l"
  qdf_count_tmp=`#{cmd}`.chomp.to_i

  while qdf_count > 5 and $cdm_root_freemb > 300 and $cdm_opt_usedpercent > 89 
    #get one oldest qdf file
    cmd="ssh root@#{cdm} ls -ltr #{$apg_cdm_failover_storage_dir}/*qdf|head -n 1|awk '{print $9}'"
    qdf_file=`#{cmd}`.chomp
    cmd="ssh root@#{cdm} mv #{qdf_file} /tmp"
    puts cmd
    `#{cmd}`
    cmd = "ssh root@#{cdm} ls -ltr #{$apg_cdm_failover_storage_dir}/*qdf|wc -l"
    qdf_count=`#{cmd}`.chomp.to_i
  end

 while qdf_count_tmp > 0 and qdf_count < 6
    cmd="ssh root@#{cdm} ls -ltr /tmp/*qdf|head -n 1|awk '{print $9}'"
    qdf_tmp_file=`#{cmd}`.chomp
    cmd="ssh root@#{cdm} mv #{qdf_tmp_file} #{$apg_cdm_failover_storage_dir}"
    puts cmd
    `#{cmd}`
    cmd = "ssh root@#{cdm} ls -ltr /tmp|grep qdf|wc -l"
    qdf_count_tmp=`#{cmd}`.chomp.to_i
 end
end

def self.apg_cdm_dbhost(cdm)
  get_dblist_apg
  myCDM=cdm.upcase
  cmd="grep -l ^#{myCDM}$ /root/smangam/amcalapgdb*"
  output = `#{cmd}`.chomp
  $apg_cdm_dbhost = output.split('/')[-1]
  $apg_cdm_db = $db_hash[$apg_cdm_dbhost]
end

def self.apg_cdm_list_connectors
  cmd = "ssh root@#{$cdm} cat #{$apg_collector_conf_dir}/collecting.xml |grep connector|grep true"
  puts `#{cmd}`
end

def self.apg_cdm_backend_socket_connection
  puts "data transfer of inQDumpFilennn.qdf files from CDM occurs only if a TCP connection exists between the CDM and Backend port"
  puts "if you do not see active connections, there may be a problem with the Backend"
  cmd="ssh root@#{$cdm} netstat -anp|grep '"+$apg_cdm_backend_port+" '"
  puts cmd
  puts `#{cmd}`
end

# APG SNMP Collector methods

def self.apg_cdm_snmp_collector_instances
  cmd ="ssh root@#{$cdm} ls -ltr /opt/APG/Collecting/SNMP-Collector|grep -v total|awk '{print $9}'"
  output=`#{cmd}`.chomp
  snmp_instances=output.split
  puts output
end

def self.apg_cdm_snmp_agent_list
 print "enter SNMP collector instance:"
 $snmp_collector=gets.chomp
 cmd="scp root@#{$cdm}:/opt/APG/Collecting/SNMP-Collector/#{$snmp_collector}/conf/snmp-polling-distribution.xml /root/smangam/#{$cdm}-snmp-polling-distribution.xml"
 puts `#{cmd}`
 cmd="grep 'snmp-agent name=' /root/smangam/#{$cdm}-snmp-polling-distribution.xml |awk '{print $2,$3}'"
 puts cmd
 puts `#{cmd}`
end

def self.apg_cdm_snmp_agent_group_list
 print "enter SNMP collector instance:"
 $snmp_collector=gets.chomp
 cmd="scp root@#{$cdm}:/opt/APG/Collecting/SNMP-Collector/#{$snmp_collector}/conf/snmp-polling-distribution.xml /root/smangam/#{$cdm}-snmp-polling-distribution.xml"
 puts `#{cmd}`
 cmd="grep 'snmp-agents-explicit-group name' /root/smangam/#{$cdm}-snmp-polling-distribution.xml|awk '{print $2}'|cut -d'=' -f2|cut -d'\"' -f2"
 puts `#{cmd}`
end

def self.apg_cdm_snmp_agent_groups_with_agents
 print "enter SNMP collector instance:"
 $snmp_collector=gets.chomp
 cmd="scp root@#{$cdm}:/opt/APG/Collecting/SNMP-Collector/#{$snmp_collector}/conf/snmp-polling-distribution.xml /root/smangam/#{$cdm}-snmp-polling-distribution.xml"
 puts `#{cmd}`
 cmd="egrep 'agent-ip-address|snmp-agents-explicit-group' /root/smangam/#{$cdm}-snmp-polling-distribution.xml|grep -v '/>'"
 puts cmd
 puts `#{cmd}`
end

def self.apg_cdm_snmp_pg_list
 print "enter SNMP collector instance:"
 $snmp_collector=gets.chomp
 cmd="scp root@#{$cdm}:/opt/APG/Collecting/SNMP-Collector/#{$snmp_collector}/conf/slave-snmp-poller.xml /root/smangam/#{$cdm}-slave-snmp-poller.xml"
 puts `#{cmd}`
 cmd="grep -A20 'polling-group name' /root/smangam/#{$cdm}-slave-snmp-poller.xml"
 puts `#{cmd}`
end

def self.apg_cdm_snmp_collector_masks
  print "enter SNMP Collector Instance:"
  snmp_instance=gets.chomp
  cmd ="ssh root@#{$cdm} cat /opt/APG/Collecting/SNMP-Collector/#{snmp_instance}/conf/snmp-masks.xml|grep '\<snmp-mask name='|cut -d'=' -f2|awk '{print $1}'| sed 's/\"//g'"
  puts cmd
  puts `#{cmd}`
end

###########################
# Prognosis methods
###########################

def self.prog_server_for_cdm
 $prog_cust_list={"am-amvac"=>"haup-svr-progm9", "am-haoc"=>"haup-bra-progm1"}
 puts "Prognosis Server for #{$cdm} is: "+$prog_cust_list[$cdm]
end

def self.prog_test_alert
  puts "send a test alert from the Prognosis server"
end

##########################
# Ansible methods
##########################

def self.ansible_list_ansible_hosts_file
  cmd="cat /etc/ansible/hosts"
  puts cmd
  puts `#{cmd}`
end

def self.ansible_deploy_qualys
  cmd="ansible-playbook /opt/ansible/playbooks/qualys-deployment-cdms.yml"
  puts cmd
  puts `#{cmd}`
end

def self.ansible_deploy_crowdstrike
  cmd="ansible-playbook /opt/ansible/playbooks/crowdstrike/proxy-crowdstrike-sensor-deploy-rh7.yml"
  puts cmd
  puts `#{cmd}`
end

end
