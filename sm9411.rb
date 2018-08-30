#!/usr/bin/ruby

$menu=0

def mainmenu
 puts "select an option
   1: show space
   2: clean yum
   3: check firewalld
   4: remove voyence init script
   5: comment crontab script
   5a: comment crontab script for multiT
   6: update puppet.conf
   7: run puppet
   7a: start firewalld daemon
   8: uncomment crontab script
   8a: uncomment crontab script for multiT
   9: remove ncf files
   9a: stop OI adapter
   9b: check status of OI adapter
   9c: start OI adapter
   10: clear notifcache
 system check
   11: check all versions
   12: check all services
 EXIT Program
   99: Exit"

  case gets.strip
  when "1"
    puts `df -h|grep opt`
  when "2"
   puts `yum --disablerepo=* --enablerepo=extra makecache`
  when "3"
   puts `systemctl status firewalld`
  when "4"
   puts `rm -rf /etc/systemd/system/vcmaster.service.d/`
   puts `systemctl daemon-reload`
  when "5"
   puts `cat /etc/cron.d/amcdm-crontab`
   puts "executing sed -i -E '/RIM_process_monitor.pl/s/(.*RIM_process_monitor.pl)/#\1/' /etc/cron.d/amcdm-crontab"
   puts `sed -i -E \'/RIM_process_monitor.pl/s/(.*RIM_process_monitor.pl)/#\1/\' /etc/cron.d/amcdm-crontab`
  when "5a"
   puts `cat /etc/cron.d/amcdm-crontab`
   puts "executing sed -i -E '/MultiT_NameSpace_Monitor.pl/s/(.*MultiT_NameSpace_Monitor.pl)/#\1/' /etc/cron.d/am-*_amcdm-crontab"
   puts `sed -i -E \'/MultiT_NameSpace_Monitor.pl/s/(.*MultiT_NameSpace_Monitor.pl)/#\1/\' /etc/cron.d/am-*_amcdm-crontab`
   puts `cat /etc/cron.d/amcdm-crontab`
  when "6"
   puts `sed -i \'s/environment=branches_RIM_9_4_1_0/environment=branches_RIM_9_4_1_1/\' /etc/puppet/puppet.conf`
   puts `cat /etc/puppet/puppet.conf|grep environment`
  when  "7"
    print "execute the following:"
    puts %?puppet agent --test 2>&1 | tee /var/log/puppet/puppet.log.$(date +"%Y-%m-%d-%H%M%S")?
    puts "echo ${PIPESTATUS[*]}"
  when "7a"
    puts `systemctl start firewalld`
    puts `systemctl status firewalld`
  when "8"
    puts `sed -i -E \'/RIM_process_monitor.pl/s/^#(.*RIM_process_monitor.pl)/\1/\' /etc/cron.d/amcdm-crontab`
   puts `cat /etc/cron.d/amcdm-crontab`
  when "8a"
    puts `sed -i -E \'/MultiT_NameSpace_Monitor.pl/s/^#(.*MultiT_NameSpace_Monitor.pl)/\1/\' /etc/cron.d/am-*_amcdm-crontab`
   puts `cat /etc/cron.d/amcdm-crontab`
  when "9"
    puts "rm -f /opt/InCharge9/SAM/smarts/global/conf/icoi/*ncf"
    puts `rm -f /opt/InCharge9/SAM/smarts/global/conf/icoi/*ncf`
  when "9a"
    puts `sm_service stop --all`
  when "9b"
    puts `sm_service show`
  when "9c"
    puts `sm_service start --all`
  when "10"
    mycdm=`hostname -s`.upcase.chomp
    puts "/opt/InCharge9/SAM/smarts/bin/dmctl -s AMCDM_#{mycdm}_ADAPTER_OI invoke notifProcessorInterface::singletonNotifProcessorInterface clearConfigCache"
    puts `/opt/InCharge9/SAM/smarts/bin/dmctl -s AMCDM_#{mycdm}_ADAPTER_OI invoke notifProcessorInterface::singletonNotifProcessorInterface clearConfigCache`
  when "11"
    puts `systemctl status firewalld`
    puts "expect to see VERSION=9.4.1.0.75"
    puts "expect to see NCM_PATCH=28"
    puts `grep VERSION=9.4.1.0.75 /etc/voyence.conf`
    puts `grep PATCH=28 /etc/voyence.conf`
    puts `sm_server --version |grep 'V9.4.1.23(158542)'`
    puts "expect to see SAM_SUITE: V9.4.1.23(158542)"
  when "12"
    puts `sm_service show`
    print "execute the following:"
    puts "brcontrol|grep `hostname -s`"
    puts `systemctl status voyence.service`
    puts `manage-modules.sh service status all`
  when "99"
    exit
  end
end

while $menu==0
  mainmenu
end
