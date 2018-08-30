#!/usr/bin/ruby
#########################################
# author: sunil mangam
# version: 1.3
#
#########################################

require '/root/smangam/didatacommon2'

$menu=0
$samlog_days_keep=31
$num_of_ncm_dataimages=5

def apg_status_old(cdm,myresults)
  cmd = "ssh root@"+cdm +" /opt/APG/bin/manage-modules.sh service status all |grep stopped|egrep -v 'topology|webservice' 2>/dev/null"
  output = `#{cmd}`
  if ($?.success?) then
    mytime = Time.new.to_s.chomp
    myresults.puts "#{mytime}: APG stopped service(s) for #{cdm}"
    myresults.puts "\t"+output
    if !($report_only) then
      output_arr = output.split(/\n/)
      output_arr.each do |module_line|
        # restarting the stopped APG services
        mymodule = module_line.split(/'/)
        cmd = "ssh root@"+cdm+" /opt/APG/bin/manage-modules.sh service start "+ mymodule[1]
        output2 = `#{cmd}`.chomp
        mytime = Time.new.to_s.chomp
        myresults.puts "#{mytime}: APG started service(s) for #{cdm}"
        myresults.puts "\t #{output2}"
      end
    end
  end
end

def apg_restart(cdm,myresults)
  # check if APG was recently restated
  cmd = "ssh root@"+cdm + " ps -eaf|grep apg|grep 'Default/conf'|awk '{print $7}'"
  #cmd = "ssh root@"+cdm + " ps -ea -o euser,etime|grep apg|grep -v grep| awk '$2 ~ /^01:[0-9][0-9]:[0-9][0-9]/ {print $2}'"
  output = `#{cmd}`.chomp
  if !($report_only) then
    if !(output.empty?) then
      mytime = Time.new.to_s.chomp
      myresults.puts "#{mytime}: APG was restarted recently for #{cdm} . Will not be restarted again."
    else 
      cmd = "ssh root@"+cdm +" /opt/APG/bin/manage-modules.sh service restart all 2>/dev/null"
      #output = `#{cmd}`
      mytime = Time.new.to_s.chomp
      myresults.puts "#{mytime}: APG restarted service(s) for #{cdm}"
    end
  end
end

def apg_backend_status(cdm,myresults)
  #get the backends
  cmd="ssh root@"+cdm+ " ls /opt/APG/Backends/APG-Backend"
  output=`#{cmd}`.chomp
  backends = output.split(" ")

  #get the tmp dir name
  backends.each do |backend|
    cmd="ssh root@"+cdm+ " cat /opt/APG/Backends/APG-Backend/#{backend}/conf/config.xml|grep temporary-files|grep -v '<!--'|awk '{print $3}'|cut -f2 -d'>'|cut -f1 -d'<'"
    tmpdir=`#{cmd}`.chomp
    cmd="ssh root@"+cdm+" ls -ltr #{tmpdir} | grep -v total |wc -l 2>/dev/null"
    tmpdir_files=`#{cmd}`.chomp
    if ( tmpdir_files.to_i > 80) then
      if !($report_only) then
        mytime = Time.new.to_s.chomp
        myresults.puts "#{mytime}: APG restarting backend for #{cdm} #{backend}. Total tmp files is #{tmpdir_files}"
        cmd = "ssh root@"+cdm + " manage-modules.sh service restart backend #{backend}"
        `#{cmd}`
      end
    else
      mytime = Time.new.to_s.chomp
      myresults.puts "#{mytime}: APG backend status for #{cdm} #{backend}. Total tmp files is #{tmpdir_files}"
    end
  end
end

def smarts_status(cdm,myresults)
  cmd = "ssh root@"+cdm +" sm_service show |grep 'NOT RUNNING' 2>/dev/null"
  output = `#{cmd}`
  if ($?.success?) then
   mytime = Time.new.to_s.chomp
   myresults.puts "#{mytime}: SMARTS stopped service(s) for #{cdm}"
   myresults.puts output
   output_arr = output.split(/\n/)
   output_arr.each do |module_line|
     # restarting the stopped SMARTS services
     mymodule = module_line.split(/\s+/)
     cmd = "ssh root@"+cdm+" sm_service start "+ mymodule[2]
     output2 = `#{cmd}`
     mytime = Time.new.to_s.chomp
     myresults.puts "#{mytime}: SMARTS started service(s) for #{cdm}"
     myresults.puts "\t #{output2}"
   end
  end
end

def smarts_status_all
 puts "checking SMARTS status on all CDMs..."
 File.open("/root/smangam/cdm_solo.txt").each { |a|
  x=a.chomp
  cmd = "ssh root@#{x} sm_service show |grep 'NOT RUNNING' 2>/dev/null"
  output = `#{cmd}`
  if ($?.success?) then
   puts "SMARTS stopped service(s) for #{x}"
  end
 }
end

def oiadapter_status_all
 puts "checking..."
 File.open("/root/smangam/cdm_solo.txt").each { |a|
  x=a.chomp
  cmd = "ssh root@"+x +" cat /opt/InCharge9/SAM/smarts/regional/logs/cdmHeartBeat.log|tail -n 1 2>/dev/null"
  #cmd = "ssh root@"+x +" cat /opt/InCharge9/SAM/smarts/customer/#{x}/logs/cdmHeartBeat.log|tail -n 1 2>/dev/null"
  output = `#{cmd}`.chomp
  output_arr = output.split(/\s+/)
  if (output_arr.size > 0 && output_arr[-1] != 'ok' && output_arr[-1] != '65.' && output_arr[0] != '/usr/bin/snmptrap' ) then
    puts "OIADAPTER not sending data for #{x} "
    puts "#{output}"
  end
 }
end

def oiadapter_status
  if ($cdm_type == "solo") then
   cmd = "ssh root@"+$cdm +" cat /opt/InCharge9/SAM/smarts/regional/logs/cdmHeartBeat.log|tail -n 1 2>/dev/null"
  else
   cmd = "ssh root@"+$cdm +" cat /opt/InCharge9/SAM/smarts/customer/#{$cdm}/logs/cdmHeartBeat.log|tail -n 1 2>/dev/null"
  end
  output = `#{cmd}`.chomp
  puts output
  output_arr = output.split(/\s+/)
  if (output_arr.size > 0 && output_arr[-1] != 'ok' && output_arr[-1] != '65.' && output_arr[0] != '/usr/bin/snmptrap' ) then
    puts "OIADAPTER not sending data for #{$cdm} "
    puts "#{output}"
  end
  puts "solution recommendation: restart OI Adapter service"
end

def sm_service_oi(option)
  cmd="ssh root@#{$cdm} sm_service #{option} amcdm_#{$cdm}_adapter_oi"
  puts cmd
  output=`#{cmd}`
  puts output
end

def oiadapter_status_old
  if ($cdm_type == "solo") then
   cmd = "ssh root@"+$cdm +" cat /opt/InCharge9/SAM/smarts/regional/logs/cdmHeartBeat.log|tail -n 1 2>/dev/null"
  else
   cmd = "ssh root@"+$cdm +" cat /opt/InCharge9/SAM/smarts/customer/#{$cdm}/logs/cdmHeartBeat.log|tail -n 1 2>/dev/null"
  end
  output = `#{cmd}`.chomp
  output_arr = output.split(/\s+/)
  if (output_arr.size > 0 && output_arr[-1] != 'ok' && output_arr[-1] != '65.' && output_arr[0] != '/usr/bin/snmptrap' ) then
    puts "OIADAPTER not sending data for #{$cdm} "
    puts "#{output}"
    cmd = "ssh root@"+$cdm +" sm_service show |grep 'adapter_oi' 2>/dev/null"
    output = `#{cmd}`.chomp
    if ($?.success?) then
     output_arr = output.split(/\s+/)
     if (output_arr[0] == 'RUNNING') then
       puts "stopping OIADAPTER for #{cdm} "
       cmd = "ssh root@"+$cdm+" sm_service stop "+ output_arr[1]
       output2 = `#{cmd}`
     end
    end
    `sleep 60`
    cmd = "ssh root@"+$cdm +" sm_service show |grep 'NOT' | grep 'adapter_oi' 2>/dev/null"
    output = `#{cmd}`.chomp
    if ($?.success?) then
     output_arr = output.split(/\s+/)
     if (output_arr[0] == 'NOT') then
       puts "starting OIADAPTER for #{$cdm} "
       cmd = "ssh root@"+$cdm+" sm_service start "+ output_arr[-1]
       output2 = `#{cmd}`
     end
    end
  end
end

def mem_status(cdm,myresults)
  cmd = "ssh root@"+cdm +" free -m|grep Mem|awk '{print $3*100/$2}'"
  output = `#{cmd}`.chomp.to_i
  if ($?.success? and output > 89) then
   mytime = Time.new.to_s.chomp
   myresults.puts "#{mytime}: MEMORY %USED for #{cdm} " + output.to_s
   #apg_restart(cdm,myresults)

   # check the number of free pages in each zone
   #cmd = "ssh root@"+cdm +" cat /proc/zoneinfo|grep -A 1 'Node' |grep -v '-' "
   #output = `#{cmd}`
   #myresults.puts "#{mytime}: MEMORY FREE PAGES for #{cdm} \n" + output

   # check for page allocation failures
   cmd = "ssh root@"+cdm +" cat /var/log/messages | grep 'page allocation failure'"
   output = `#{cmd}`
   myresults.puts "#{mytime}: MEMORY page alloc failures for #{cdm} " + output if !(output.empty?)

   # check for OOM
   cmd = "ssh root@"+cdm +" cat /var/log/messages | grep 'Out of memory'"
   output = `#{cmd}`
   myresults.puts "#{mytime}: MEMORY OOM for #{cdm} " + output if !(output.empty?)
  end
end

def hyperic_status(cdm,myresults)
  cmd = "ssh root@"+cdm +" /opt/hyperic/agent-*cdm/bin/hq-agent.sh status |grep 'HQ Agent' "
  output = `#{cmd}`.chomp
  if ($?.success? and output =~ /not/) then
   mytime = Time.new.to_s.chomp
   myresults.puts "#{mytime}: HYPERIC for #{cdm} " + output
   cmd = "ssh root@"+cdm +" /opt/hyperic/agent-*cdm/bin/hq-agent.sh start"
   `#{cmd}`
  end
end

def vcmaster_status(cdm,myresults)
  cmd = "ssh root@"+cdm +" systemctl status vcmaster.service |grep 'Active:' 2>/dev/null"
  output = `#{cmd}`.chomp
  if ($?.success? and output =~ /inactive/) then
   mytime = Time.new.to_s.chomp
   myresults.puts "#{mytime}: NCM vcmaster for #{cdm} " + output
   cmd = "ssh root@"+cdm +" systemctl start vcmaster.service"
   `#{cmd}`
  end
end

def ncm_status
  cmd="ssh root@#{$cdm} ps -eaf|grep voyenced"
  output = `#{cmd}`.chomp
  puts output
  cmd="ssh root@#{$cdm} ps -eaf|grep voyenced|head -n 1|awk '{print $2}'"
  voyenced_pid = `#{cmd}`.chomp
  cmd="ssh root@#{$cdm} ps -eaf|grep #{voyenced_pid}"
  output = `#{cmd}`.chomp
  puts output
end

def sysmon_status
  cmd="ssh root@"+$cdm +" service sysadmin status"
  output = `#{cmd}`.chomp
  if ($?.exitstatus != 0) then
    puts "NCM sysmon is not running for #{$cdm} " + output
  else
    puts "NCM sysmon is running for #{$cdm} " + output
  end
end

def sysmon_start
  puts "restarting NCM sysmon for #{$cdm}"
  cmd="ssh root@"+$cdm +" service sysadmin start"
  puts `#{cmd}`
end

def fs_status_all_b
  File.open("/root/smangam/cdm_solo.txt").each { |a|
   x=a.chomp
   cmd = "ssh root@"+x +" df -m|grep opt | grep -v Filesystem|awk '{print $5,$4/1024,$6}'|sed 's/%//g' | awk '{if ($1 > 89 && $2 < 1.1) print $3,$2,$1}'"
   output = `#{cmd}`.chomp
   if !output.empty?
    puts "DISK USAGE for #{x} is: " + output +"%"
   end
 }

 File.open("/root/smangam/cdm_multi.txt").each { |a|
   x=a.chomp
   cmd = "ssh root@"+x +" df -m|grep opt | grep -v Filesystem|awk '{print $5,$4/1024,$6}'|sed 's/%//g' | awk '{if ($1 > 89 && $2 <1.1) print $3,$2,$1}'"
   output = `#{cmd}`.chomp
   if !output.empty?
    puts "DISK USAGE for #{x} is: " + output +"%"
   end
 }

 File.open("/root/smangam/cdm_cal.txt").each { |a|
   x=a.chomp
   cmd = "ssh root@"+x +" df -m|grep opt | grep -v Filesystem|awk '{print $5,$4/1024,$6}'|sed 's/%//g' | awk '{if ($1 > 89 && $2 <1.1) print $3,$2,$1}'"
   output = `#{cmd}`.chomp
   if !output.empty?
    puts "DISK USAGE for #{x} is: " + output +"%"
   end
 }
end

def mainmenu
 puts "select an option
   0: enter CDM
   1: build CDM list
 CPU Usage
   50: check CPU usage
 Filesystem Checks
    9: expected disk space usage
   10: check filesystem space for #{$cdm}
   11: list CDMs where filesystems are >90% full
   12: cleanup old logs for #{$cdm}
   13: cleanup old logs for CDMs where filesystem is >90% full
 Check Disk Usage
   15: list disk usage for a given directory path on #{$cdm}
   16: list files in a directory on #{$cdm}
   17: delete a file on #{$cdm}
 SMARTS Checks
   20: start/stop/show sm_service for #{$cdm}
   21: list of CDMs where SMARTS services are not running
 OI Adapter Checks
   22: list CDMs where OI Adapter has an error
   23: check OI Adapter error for #{$cdm}
 NCM Checks
   30: check NCM sysmon(system manager) status for #{$cdm}
   31: restart NCM sysmon(system manager) for #{$cdm}
   32: NCM master service (voyenced) status
 APG Checks
   40: APG service status for #{$cdm}
   41: APG service status for all CDMs
   42: APG restart service for #{$cdm}
   43: APG failed filter status for #{$cdm}
   44: APG failed filter status for all CDMs
 EXIT Program
   99: Exit"

  case gets.strip
  when "0"
    Didatacommon.get_cdm
  when "1"
    Didatacommon.cdm_build_list 
  when "50"
    Didatacommon.cpu_usage
  when "9"
    Didatacommon.fs_normal_usage
  when "10"
    Didatacommon.fs_status
  when "11"
    Didatacommon.fs_status_all
  when "12"
    print "enter how many days of logs you want to keep in samlog (default is 31):"
    $samlog_days_keep=gets.chomp
    print "enter the number of NCM data images to keep (default is 5):"
    $num_of_ncm_dataimages=gets.chomp
    Didatacommon.fs_cleanup($cdm)
  when "13"
    Didatacommon.fs_cleanup_all
  when "15"
    Didatacommon.du_status
  when "16"
    Didatacommon.ls_status
  when "17"
    Didatacommon.delete_file
  when "20"
    Didatacommon.sm_service
  when "21"
    smarts_status_all
  when "22"
    oiadapter_status_all
  when "23"
    oiadapter_status
  when "30"
    sysmon_status
  when "31"
    sysmon_start
  when "32"
    ncm_status
  when "40"
    Didatacommon.apg_service_status
  when "41"
    Didatacommon.apg_service_status_all
  when "42"
    Didatacommon.apg_service_manage
  when "43"
    Didatacommon.apg_cdm_failover_filter_status
  when "44"
    Didatacommon.apg_cdm_failover_filter_status_all
  when "99"
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

