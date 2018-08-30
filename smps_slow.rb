#!/usr/bin/ruby
#########################################
# author: sunil mangam
# version: 1.3
#
#########################################

def build_cdm_list
 cdm_solo_str = `grep "^node" /etc/puppet/manifests/site.pp |grep 'am-'|awk '{print $2}' | sed "s/\'//g" |sed "s/\.us\.gsoa\.local//g"`
 cdm_cal_str = `grep "^node" /etc/puppet/manifests/site.pp |grep 'amc'|awk '{print $2}' | sed "s/\'//g" |sed "s/\.us\.gsoa\.local//g"`
 cdm_multi_str = `grep "am-" /etc/puppet/manifests/site.pp | grep ":" |grep -v "#" | sed 's/\"//g'| sed "s/://g"`

 cdm_solo_arr = cdm_solo_str.split.sort!
 cdm_cal_arr = cdm_cal_str.split.sort!
 cdm_multi_arr = cdm_multi_str.split.sort!

 # check if ssh to the host is working
 cdm_solo_arr.each do |cdm|
  cmd="ssh -o 'PreferredAuthentications=publickey' root@"+cdm + " hostname >/dev/null 2>&1"
  if !(system(cmd)) then
   cdm_solo_arr -= [cdm]
  end
 end
 cdm_cal_arr.each do |cdm|
  cmd="ssh -o 'PreferredAuthentications=publickey' root@"+cdm + " hostname >/dev/null 2>&1"
  if !(system(cmd)) then
   cdm_cal_arr -= [cdm]
  end
 end

 # check if any cdm is a multiT
 cdm_solo_arr.each do |cdm|
  cmd = "ssh root@"+cdm+" sm_service show >/dev/null 2>&1"
  if (system(cmd)) then
   cmd = "ssh root@"+cdm+" sm_service show |grep namespace >/dev/null 2>&1"
   if (system(cmd)) then
     cdm_solo_arr -= [cdm]
     cdm_multi_arr += [cdm]
   end
  end
 end

 File.open("/root/smangam/cdm_solo.txt","w") do |f|
  f.puts cdm_solo_arr
  f.close
 end
 File.open("/root/smangam/cdm_cal.txt","w") do |f|
  f.puts cdm_cal_arr
  f.close
 end
 File.open("/root/smangam/cdm_multi.txt","w") do |f|
  f.puts cdm_multi_arr
  f.close
 end
end

def apg_status(cdm,myresults)
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

def oiadapter_lockfiles(cdm,myresults,cdm_type)
  if (cdm_type == "solo") then
   cmd = "ssh root@"+cdm +" ls -ltr /opt/InCharge9/SAM/smarts/regional/logs/*ADAPTER*lck |wc -l 2>/dev/null"
   cmd2 = "ssh root@"+cdm +" rm -rf /opt/InCharge9/SAM/smarts/regional/logs/*ADAPTER*lck"
  else
   cmd = "ssh root@"+cdm +" ls -ltr /opt/InCharge9/SAM/smarts/customer/#{cdm}/logs/*ADAPTER*lck|wc -l 2>/dev/null"
   cmd2 = "ssh root@"+cdm +" rm -rf /opt/InCharge9/SAM/smarts/customer/#{cdm}/logs/*ADAPTER*lck"
  end
  output = `#{cmd}`.chomp
  if (output.to_i > 40) then
    puts "total files for #{cdm} is #{output}" 
    `#{cmd2}`
  end
end

def oiadapter_status(cdm,myresults,cdm_type)
  if (cdm_type == "solo") then
   cmd = "ssh root@"+cdm +" cat /opt/InCharge9/SAM/smarts/regional/logs/cdmHeartBeat.log|tail -n 1 2>/dev/null"
  else
   cmd = "ssh root@"+cdm +" cat /opt/InCharge9/SAM/smarts/customer/#{cdm}/logs/cdmHeartBeat.log|tail -n 1 2>/dev/null"
  end
  output = `#{cmd}`.chomp
  output_arr = output.split(/\s+/)
  if (output_arr.size > 0 && output_arr[-1] != 'ok' && output_arr[-1] != '65.' && output_arr[0] != '/usr/bin/snmptrap' ) then
    mytime = Time.new.to_s.chomp
    myresults.puts "#{mytime}: OIADAPTER not sending data for #{cdm} "
    myresults.puts "\t #{output}"
    cmd = "ssh root@"+cdm +" sm_service show |grep 'adapter_oi' 2>/dev/null"
    output = `#{cmd}`.chomp
    if ($?.success?) then
     output_arr = output.split(/\s+/)
     if (output_arr[0] == 'RUNNING') then
       mytime = Time.new.to_s.chomp
       myresults.puts "#{mytime}: stopping OIADAPTER for #{cdm} "
       cmd = "ssh root@"+cdm+" sm_service stop "+ output_arr[1]
       output2 = `#{cmd}`
     end
    end
    `sleep 60`
    cmd = "ssh root@"+cdm +" sm_service show |grep 'NOT' | grep 'adapter_oi' 2>/dev/null"
    output = `#{cmd}`.chomp
    if ($?.success?) then
     output_arr = output.split(/\s+/)
     if (output_arr[0] == 'NOT') then
       mytime = Time.new.to_s.chomp
       myresults.puts "#{mytime}: starting OIADAPTER for #{cdm} "
       cmd = "ssh root@"+cdm+" sm_service start "+ output_arr[-1]
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

def sysmon_status(cdm,myresults)
  cmd="ssh root@"+cdm +" service sysadmin status"
  output = `#{cmd}`.chomp
  if ($?.exitstatus != 0) then
    mytime = Time.new.to_s.chomp
    myresults.puts "#{mytime}: NCM sysmon is not running for #{cdm} " + output
    if !($report_only) then
      cmd="ssh root@"+cdm +" service sysadmin start"
      `#{cmd}`
    end
  end
end

def fs_opt_status(cdm,myresults,cdm_type)
  cmd = "ssh root@"+cdm +" df -m|grep opt | grep -v Filesystem|awk '{print $5,$4/1024,$6}'|sed 's/%//g' | awk '{if ($1 > 89) print $1,$2,$3}'"
  output = `#{cmd}`.chomp
  if !(output.empty?) then
    mytime = Time.new.to_s.chomp
    myresults.puts "#{mytime}: DISK USAGE for #{cdm} [% MB filesystem] " + output

    if !($report_only) then
    # check if APG qdf data is filling up. if so, exit from this method
    cmd = "ssh root@"+cdm +" ls -ltr /opt/APG/Collecting/FailOver-Filter/Default/tmp-backend |wc -l 2>/dev/null"
    output = `#{cmd}`.chomp
    if (output.to_i > 3) then
     mytime = Time.new.to_s.chomp
     myresults.puts "#{mytime}: DISK FULL for #{cdm} due to APG qdf files filling up. Total files: " + output
    end
   
    # delete samlog logs that are older than 31 days and larger than 1M
    if (cdm_type == "solo") then
     cmd = "ssh root@"+cdm +" find /opt/InCharge9/SAM/smarts/regional/logs -mtime +31 -size +1M"
    else
     cmd = "ssh root@"+cdm +" find /opt/InCharge9/SAM/smarts/customer/#{cdm}/logs -mtime +31 -size +1M 2>/dev/null"
    end
    output = `#{cmd}`
    if ($?.success?) then
      myresults.puts "#{mytime}: deleting samlog files older than 31 days for #{cdm} "
      output_arr = output.split(/\n/)
      output_arr.each do |f|
        cmd = "ssh root@"+cdm +" rm -rf #{f}"
        `#{cmd}`
      end
    end

    # delete samlog archive logs that are older than 10 days and larger than 1M
    if (cdm_type == "solo") then
     cmd = "ssh root@"+cdm +" find /opt/InCharge9/SAM/smarts/regional/logs/archives -mtime +10 -size +1M"
    else
     cmd = "ssh root@"+cdm +" find /opt/InCharge9/SAM/smarts/customer/#{cdm}/logs/archives -mtime +10 -size +1M 2>/dev/null"
    end
    output = `#{cmd}`
    if ($?.success?) then
      myresults.puts "#{mytime}: deleting samlog archive files older than 10 days for #{cdm} "
      output_arr = output.split(/\n/)
      output_arr.each do |f|
        cmd = "ssh root@"+cdm +" rm -rf #{f}"
        `#{cmd}`
      end
    end

    # gzip the samlog that are older than 7 days and larger than 1M
    if (cdm_type == "solo") then
      cmd = "ssh root@"+cdm +" find /opt/InCharge9/SAM/smarts/regional/logs -mtime +7 -size +1M|grep -v '.gz'"
    else
      cmd = "ssh root@"+cdm +" find /opt/InCharge9/SAM/smarts/customer/#{cdm}/logs -mtime +7 -size +1M|grep -v '.gz'"
    end
    output = `#{cmd}`
    if ($?.success?) then
      myresults.puts "#{mytime}: zipping the file for #{cdm} "
      output_arr = output.split(/\n/)
      output_arr.each do |f|
        cmd = "ssh root@"+cdm +" gzip #{f}"
        `#{cmd}`
      end
    end

    # clear the samlog audit archive logs
    if (cdm_type == "solo") then
      cmd = "ssh root@"+cdm +" du -ks /opt/InCharge9/SAM/smarts/regional/logs/archives/*audit* | wc -l 2>/dev/null"
    else
      cmd = "ssh root@"+cdm +" du -ks /opt/InCharge9/SAM/smarts/customer/#{cdm}/logs/archives/*audit* | wc -l 2>/dev/null"
    end
    output = `#{cmd}`.chomp
    if (output.to_i > 4) then
      myresults.puts "#{mytime}: deleting audit files for #{cdm} "
      cmd = "ssh root@"+cdm +" rm -rf /opt/InCharge9/SAM/smarts/regional/logs/archives/*audit*"
      `#{cmd}`
    end

    # clear NCM date-images
    cmd = "ssh root@"+cdm +" ls -ltr /opt/smarts-ncm/data-image|grep -v total| wc -l"
    output = `#{cmd}`.chomp
    if (output.to_i > 6) then
      # keep only the recent 6 backups
      files_to_delete = output.to_i - 6
      cmd = "ssh root@"+cdm +" ls -ltr /opt/smarts-ncm/data-image |grep -v total | head -n #{files_to_delete}"
      output = `#{cmd}`
      output_arr = output.split(/\n/)
      output_arr.each do |f|
        myfile = f.split(/\s+/)
        myresults.puts "#{mytime}: deleting file for #{cdm} " + myfile[-1]
        cmd = "ssh root@"+cdm +" rm -rf /opt/smarts-ncm/data-image/"+ myfile[-1]
        `#{cmd}`
      end
    end
    end
  end
end


def program_status()
 cmd = "ps -eaf|grep smps_slow.rb|grep -v grep |wc -l"
 output = `#{cmd}`.chomp
 if (output.to_i > 2) then
  mytime = Time.new.to_s.chomp
  puts output +" #{mytime} program already running. exiting"
  exit
 end
end


##########################
# main program
##########################
$report_only = true
program_status()
myresults = File.new("/root/smangam/smps_output_slow.txt","a")
mytime1 = Time.new
mytime = Time.new.to_s.chomp
myresults.puts "\n***begin*** #{mytime}"

#build_cdm_list()

# process all the solo CDMs
File.open("/root/smangam/cdm_solo.txt").each do |x|
 cdm = x.chomp
 cdm_type = "solo"
 #hyperic_status(cdm,myresults)
 #vcmaster_status(cdm,myresults)
 #sysmon_status(cdm,myresults)
 #mem_status(cdm,myresults)
 oiadapter_lockfiles(cdm,myresults,cdm_type)
 if (Time.new.hour % 2 == 0 && Time.new.min < 30) then
   fs_opt_status(cdm,myresults,cdm_type)
 end
end

# process all the multi CDMs
File.open("/root/smangam/cdm_multi.txt").each do |x|
 cdm = x.chomp
 cdm_type = "multi"
 #hyperic_status(cdm,myresults)
 #vcmaster_status(cdm,myresults)
 #mem_status(cdm,myresults)
 oiadapter_lockfiles(cdm,myresults,cdm_type)
 if (Time.new.hour % 2 == 0 && Time.new.min < 30) then
  fs_opt_status(cdm,myresults,cdm_type)
 end
end

["amcalapgdb01","amcalapgdb02"].each do |cdm|
  #apg_backend_status(cdm,myresults)
end

File.open("/root/smangam/cdm_cal.txt").each do |x|
  if x =~ /ncm/
   cdm = x.chomp
   cdm_type = "solo"
   #vcmaster_status(cdm,myresults)
   if (Time.new.hour % 2 == 0 && Time.new.min < 30) then
    fs_opt_status(cdm,myresults,cdm_type)
   end 
  end
end

myresults.close
