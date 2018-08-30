#!/usr/bin/ruby
#########################################
# author: sunil mangam
# version: 1.3
#
#########################################

$menu=0

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

def get_cdm
  print "Please enter the CDM (example am-goldcorp:) "
  $cdm = gets.chomp
  $CDM = $cdm.upcase
  if system("grep #{$cdm} /root/smangam/cdm_solo.txt")
    $cdm_type="solo"
  elsif system("grep #{$cdm} /root/smangam/cdm_multi.txt")
    $cdm_type="multi"
  end
end

def apg_failover_filter_status
  puts "the count of files in /opt/APG/Collecting/FailOver-Filter/ should be <10"
  cmd = "ssh root@#{$cdm} ls -ltr /opt/APG/Collecting/FailOver-Filter/Default/tmp"
  puts `#{cmd}`
end

def apg_failover_filter_status_all
  puts "the size of /opt/APG/Collecting/FailOver-Filter/ should be 0"
  File.open("/root/smangam/cdm_solo.txt").each { |a|
    x=a.chomp
    cmd = "ssh root@#{x} du -ms /opt/APG/Collecting/FailOver-Filter/* 2>/dev/null "
    count,path=`#{cmd}`.chomp.split
    if count.to_i >1;printf("%20s :%-5s %-50s\n",x,count,path);end
    #system("#{cmd}")
  }
end

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

####APG SNMP Collector Functions

def snmp_collector_instances
  cmd ="ssh root@#{$cdm} ls -ltr /opt/APG/Collecting/SNMP-Collector|grep -v total|awk '{print $9}'"
  output=`#{cmd}`.chomp
  snmp_instances=output.split
  puts output
end

def validate_snmp_polling_distribution
  print "enter SNMP collector instance:"
  instance=gets.chomp
  cmd ="ssh root@#{$cdm} cat /opt/APG/Collecting/SNMP-Collector/#{instance}/conf/snmp-polling-distribution.xml"
  puts `#{cmd}`
end

def update_snmp_polling_distribution_from_backup
  print "enter SNMP collector instance:"
  instance=gets.chomp
  cmd ="ssh root@#{$cdm} ls -ltr /opt/APG/Collecting/SNMP-Collector/#{instance}/conf/"
  puts "list of files in /opt/APG/Collecting/SNMP-Collector/#{instance}/conf"
  puts `#{cmd}`
  print "enter file to view:"
  myfile = gets.chomp
  cmd ="ssh root@#{$cdm} cat /opt/APG/Collecting/SNMP-Collector/#{instance}/conf/#{myfile}"
  puts `#{cmd}`
  print "enter source file to copy to snmp-polling-distribution.xml (enter n to cancel):"
  sourcefile=gets.chomp
  if sourcefile != 'n'
    cmd = "ssh root@#{$cdm} cp /opt/APG/Collecting/SNMP-Collector/#{instance}/conf/#{sourcefile} /opt/APG/Collecting/SNMP-Collector/#{instance}/conf/snmp-polling-distribution.xml"
    puts cmd
    puts `#{cmd}`
  end
end

def update_snmp_polling_distribution_from_template
  print "enter SNMP collector instance:"
  instance=gets.chomp
  cmd ="ssh root@#{$cdm} ifconfig|grep 152|awk '{print $2}'"
  internal_ip=`#{cmd}`.chomp
  puts "internal ip address is #{internal_ip}"
  if instance == 'Americas'
    instance_name = "#{$CDM}-SnmpCollector-Custom"
  elsif instance == 'Default'
    instance_name = "#{$CDM}-SnmpCollector"
  end
  puts "snmp instance name is #{instance_name}"

  if instance == 'Americas'
   cmd = "cp snmp-polling-distribution_Americas.xml /root/smangam/snmp-polling-distribution_Americas.xml.#{$cdm}"
   `#{cmd}`
   cmd = "sed -i "+ "'" + "s/AM-HERITAGE-MSCUC/#{$CDM}/" +"'" + " /root/smangam/snmp-polling-distribution_Americas.xml.#{$cdm}"
   puts `#{cmd}`
   cmd = "sed -i "+ "'" + "s/152.110.240.239/#{internal_ip}/" +"'" + " /root/smangam/snmp-polling-distribution_Americas.xml.#{$cdm}"
   puts `#{cmd}`
   cmd = "scp /root/smangam/snmp-polling-distribution_Americas.xml.#{$cdm} root@#{$cdm}:/opt/APG/Collecting/SNMP-Collector/#{instance}/conf/snmp-polling-distribution.xml"
   puts `#{cmd}`
  elsif instance == 'Default'
   cmd = "cp snmp-polling-distribution_Default.xml /root/smangam/snmp-polling-distribution_Default.xml.#{$cdm}"
   `#{cmd}`
   cmd = "sed -i "+ "'" + "s/AM-HERITAGE-MSCUC/#{$CDM}/" +"'" + " /root/smangam/snmp-polling-distribution_Default.xml.#{$cdm}"
   puts `#{cmd}`
   cmd = "sed -i "+ "'" + "s/152.110.240.239/#{internal_ip}/" +"'" + " /root/smangam/snmp-polling-distribution_Default.xml.#{$cdm}"
   puts `#{cmd}`
   cmd = "scp /root/smangam/snmp-polling-distribution_Default.xml.#{$cdm} root@#{$cdm}:/opt/APG/Collecting/SNMP-Collector/#{instance}/conf/snmp-polling-distribution.xml"
   puts `#{cmd}`
  end
end

def mainmenu
 puts "select an option
   0: enter CDM
   1: build CDM list
 APG CDM (Collecting component)
   10: APG service status for #{$cdm}
   11: APG service restart for #{$cdm}
   12: Raw data backlog for #{$cdm} (when collected raw data cannot be sent to the Backend, files are stored here)
   13: Raw data backlog for all CDMs
   15: CDM Backend Socket Connector Details (CDM sends data to this Backend)
 APG CDM SNMP Collector
   30: SNMP Collector instances for #{$cdm}
   31: validate snmp-polling-distribution.xml for SNMP Collector instance
   32: update snmp-polling-distribution.xml from backup for SNMP Collector instance
   33: update snmp-polling-distribution.xml from template for SNMP Collector instance
 APG CAL (Backend or the Processing component)
   20: about processing component (takes the raw data from the collecting component, aggregates it, and sends it to MySQL database)
   21: enter APG Backend host (amcalapgdb01,2,3,4,5,6,7,amcalapgbkend02,3,4)
   22: APG service status for #{$amcalapgdb}
   23: APG service restart for #{$amcalapgdb}
   24: processing component listening port
   25: status of temp directory (aggregated data is stored here, before sending to MySQL database)
   26: details of MySQL database to which processing component sends data
 EXIT Program
   99: Exit"
  case gets.strip
  when "0"
    get_cdm
  when "1"
    build_cdm_list 
  when "10"
    apg_status($cdm)
  when "11"
    apg_service_start($cdm)
  when "12"
    apg_failover_filter_status
  when "13"
    apg_failover_filter_status_all
  when "15"
    apg_backend_socketconnector
  when "30"
    snmp_collector_instances
  when "31"
    validate_snmp_polling_distribution
  when "32"
    update_snmp_polling_distribution_from_backup
  when "33"
    update_snmp_polling_distribution_from_template
  when "20"
    puts "the processing component collects the raw data, and aggregates are computed (avg, min, max, etc)."
    puts "this component receives data via a socket interface (listens on a TCP/IP port)"
    puts "the received raw data is processed in the processing component, and the processed data is stored in a temp directory"
    puts "the files from the tmp directory are sent to the MySQL database"
    puts "the temp directory should be normally empty, unless the connection to the MySQL database is broken, or MySQL database is slow"
    puts "restart the backend process in case the connection to MySQL database is broken"
  when "21"
    print "enter the APG Backend hostname:"
    $amcalapgdb = gets.chomp
  when "22"
    apg_status($amcalapgdb)
  when "23"
    apg_service_start($amcalapgdb)
  when "24"
    backend_listen_port
  when "25"
    backend_tmpdir_status
  when "26"
    backend_mysql_info
  when "99"
    exit
  end
end

while $menu==0
  if $cdm != nil
    puts "CDM is #{$cdm}. CDM type is #{$cdm_type}"
  else
   get_cdm
  end
  mainmenu
end

