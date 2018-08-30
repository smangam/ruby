#!/usr/bin/ruby
#######################################
# program to configure new multi-t cdm
# author: sunil mangam
#######################################

$menu=0

def get_cdm
  print "enter base cdm:"
  $cdm=gets.chomp
  $CDM=$cdm.upcase
end

def sm_service(option)
  cmd="ssh root@#{$cdm} sm_service #{option}" 
  puts cmd
  output=`#{cmd}`
  puts output
end

def update_puppetconf
  cmd="scp root@#{$cdm}:/etc/puppet/puppet.conf /root/smangam/puppet_temp.conf"
  if system("#{cmd}")
    puts "success: #{cmd}"
  else
    puts "fail: #{cmd}"
  end
  cmd="sed '" +"s/branches_RIM_9_4_0_0/branches_RIM_9_4_1_0/g" +"' puppet_temp.conf > /root/smangam/puppet.conf"
  if system("#{cmd}")
    puts "success: #{cmd}"
    cmd="scp /root/smangam/puppet.conf root@#{$cdm}:/etc/puppet/puppet.conf"
    if system("#{cmd}")
      puts "success: #{cmd}"
    else
      puts "fail: #{cmd}"
    end
  else
    puts "fail: #{cmd}"
  end
end

def cronjob
  cmd="scp root@#{$cdm}:/etc/cron.d/amcdm-crontab /root/smangam/"
  if system("#{cmd}")
    puts "success: #{cmd}"
  else
    puts "fail: #{cmd}"
  end
  cmd="sed '" +"s/am-template/#{$tenantcdm}/g" +"' am-template_amcdm-crontab > /root/smangam/#{$tenantcdm}_amcdm-crontab"
  puts cmd
  system("#{cmd}")
  cmd="scp /root/smangam/#{$tenantcdm}_amcdm-crontab  root@#{$basecdm}:/etc/cron.d"
  if system("#{cmd}")
    puts "success: #{cmd}"
  else
    puts "fail: #{cmd}"
  end
end

def apg_ncm_status
  cmd="ssh root@#{$cdm} /opt/APG/bin/manage-modules.sh service status all"
  output=`#{cmd}`
  puts output
  cmd="ssh root@#{$cdm} systemctl status vcmaster.service"
  output=`#{cmd}`
  puts output
  cmd="ssh root@#{$cdm} brcontrol|grep -i #{$cdm}"
  puts `#{cmd}`
end

def mainmenu
  puts "
 CDM Information
   0: enter CDM
 Steps on CDM #{$cdm}
   10: check firewalld is running
   10a: start firewalld
   11: check / and /opt free space (must be 1.2GB and 2.0GB)
   12: remove sysadmin from systemd system
   13: remove synapse package
   14: update /etc/puppet/puppet.conf. change environment=branches_RIM_9_4_1_0
   15: validate /etc/puppet/puppet.conf. change environment=branches_RIM_9_4_1_0
   16: validate /etc/cron.d/amcdm-crontab (comment off RIM_process_monitor.pl)
 Puppet Run
   25: stop sm_service
   26: move APG files
   29: sysadmin status
   30: stop sysadmin
   31: voyence status
   31a: stop voyence
   32: execute puppet: puppet agent --test 2>&1 | tee /var/log/puppet/puppet.log.$(date +'%Y-%m-%d-%H%M%S')
   33: monitor puppet log file /var/log/puppet/puppet.log.$(date +%Y-%m-%d-%H%M%S)
   34: print Errors from puppet log file /var/log/puppet/puppet.log.$(date +%Y-%m-%d-%H%M%S)
   35: cleanup /opt/rim/installers/apg to create more space in /opt
   36: actiate Americas custom SNMP collector
 Post Puppet Run
   20: start/stop/show sm_service
   21: check if firewalld is running
   22: check voyence/smarts/apg version
   23: check apg and vcmaster
   99: Exit"
  print "select an option:"
  case gets.strip
  when "0"
    get_cdm
  when "10"
    cmd="ssh root@#{$cdm} systemctl status firewalld"
    puts `#{cmd}`
  when "10a"
    cmd="ssh root@#{$cdm} systemctl start firewalld"
    puts `#{cmd}`
  when "11"
    cmd="ssh root@#{$cdm} df -h"
    puts `#{cmd}`
  when "12"
    cmd="ssh root@#{$cdm} rm -rf /etc/systemd/system/vcmaster.service.d"
    puts `#{cmd}`
    cmd="ssh root@#{$cdm} ls /etc/systemd/system/vcmaster.service.d"
    puts `#{cmd}`
  when "13"
    cmd="ssh root@#{$cdm} rpm --erase --nodeps --noscripts apache_synapse-2.0.0-4753.x86_64"
    puts `#{cmd}`
  when "14"
    update_puppetconf
  when "15"
    cmd="ssh root@#{$cdm} cat /etc/puppet/puppet.conf"
    puts `#{cmd}`
  when "16"
    cmd="ssh root@#{$cdm} cat /etc/cron.d/amcdm-crontab"
    puts `#{cmd}`
  when "29"
    cmd="ssh root@#{$cdm} systemctl status sysadmin"
    puts `#{cmd}`
    cmd="ssh root@#{$cdm} service sysadmin status"
    puts `#{cmd}`
    cmd="ssh root@#{$cdm} ps -eaf|grep sysmon"
    puts `#{cmd}`
  when "30"
    cmd="ssh root@#{$cdm} systemctl stop sysadmin"
    puts `#{cmd}`
  when "31"
    cmd="ssh root@#{$cdm} ps -eaf|grep voyence"
    puts `#{cmd}`
    print "enter voyence pid:"
    pid=gets.chomp
    cmd="ssh root@#{$cdm} ps -eaf|grep #{pid}"
    puts `#{cmd}`
    cmd="ssh root@#{$cdm} netstat -anp|grep 999"
    puts `#{cmd}`
  when "31a"
    cmd="scp /root/smangam/ncmstop.sh root@#{$cdm}:/root"
    if system("#{cmd}")
      puts "success: #{cmd}"
      cmd="ssh root@#{$cdm} /root/ncmstop.sh"
      puts `#{cmd}`
    else
      puts "fail: #{cmd}"
    end
  when "33"
    cmd="ssh root@#{$cdm} ls -ltr /var/log/puppet/puppet.log*"
    puts `#{cmd}`
    puts "enter log file:"
    myfile=gets.chomp
    cmd="ssh root@#{$cdm} tail -n 10  #{myfile}"
    puts `#{cmd}`
  when "34"
    cmd="ssh root@#{$cdm} ls -ltr /var/log/puppet/puppet.log*"
    puts `#{cmd}`
    puts "enter log file:"
    myfile=gets.chomp
    cmd="ssh root@#{$cdm} grep Error: #{myfile}"
    puts `#{cmd}`
    cmd="ssh root@#{$cdm} grep Warning: #{myfile}"
    puts `#{cmd}`
  when "35"
    cmd="ssh root@#{$cdm} rm -rf /opt/rim/installers/*"
    puts `#{cmd}`
  when "36"
    cmd="ssh root@#{$cdm} /opt/rim/scripts/monitorAPGSNMPAmericas.sh"
    puts `#{cmd}`
  when "20"
    print "enter the option for sm_service(show,start --all,stop --all):"
    output=gets.chomp
    sm_service(output)
  when "25"
    print "enter the option for sm_service(show,start --all,stop --all):"
    output=gets.chomp
    sm_service(output)
  when "26"
     cmd="ssh root@#{$cdm} mv /opt/APG/Collecting/SNMP-Collector/Default /opt/APG/Collecting/SNMP-Collector/Default-BKP"
     puts `#{cmd}`
     cmd="ssh root@#{$cdm} ls /opt/APG/Collecting/SNMP-Collector/Default-BKP"
     puts `#{cmd}`
     cmd="ssh root@#{$cdm} mv /opt/APG/Collecting/XML-Collector/Default /opt/APG/Collecting/XML-Collector/Default-BKP"
     puts `#{cmd}`
     cmd="ssh root@#{$cdm} ls /opt/APG/Collecting/XML-Collector/Default-BKP"
     puts `#{cmd}`
  when "21"
    cmd="ssh root@#{$cdm} systemctl status firewalld"
    puts `#{cmd}`
    cmd="ssh root@#{$cdm} iptables -nvL"
    puts `#{cmd}`
  when "22"
    cmd="ssh root@#{$cdm} grep VERSION /etc/voyence.conf"
    puts `#{cmd}`
    cmd="ssh root@#{$cdm} sm_server --version"
    puts `#{cmd}`
    cmd="ssh root@#{$cdm} manage-modules.sh list installed --match='webservice-gateway'"
    puts cmd
    puts `#{cmd}`
  when "23"
    apg_ncm_status
  when "99"
    $menu=1 
  end
end

while $menu==0
  mainmenu
end

