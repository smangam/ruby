#!/usr/bin/ruby
###############################
# author: sunil mangam
# this script is used for NCM TS
###############################
#

require '/root/smangam/didatacommon2'

$menu=0

def search_device_byip
  puts "NCM creates a device name using alias, hostname, or fqdn. this order can be changed in NCM app server, System Admin, Global, Device Options, Device Naming Scheme"
  puts "sometimes the device name in ITSM may not match the name in NCM"
  print "enter device ip address:"
  ip=gets.chomp
  ncmappservers=["amcdlncmapp01","amcdlncmapp02","amcdlncmapp03","amcdlncmapp04"]
  ncmappservers.each { |x|
    cmd="grep #{ip} /root/smangam/#{x}_cflist.txt"
    output=`#{cmd}`
    puts output
  }
end

def select_driver_based_on_snmp
  print "A device driver is selected for a given device usihg SNMP as follows:"
  print "Each of the model.xml files in /opt/smarts-ncm/custompackage/pkgxml is searched for a matching entry for the device's sysobjectid (example, /opt/smarts-ncm/custompackage/pkgxml/CiscoCustom_CiscoIOS_DDAM/CiscoCustom_CiscoIOS_DDAMModels.xml)"
  print "In autodisc.log file, the SNMP search begins with ------ SNMP Discovery Order"
end

def mainmenu
 puts "select an option
   0: enter CDM
   1: NCM services status
   2: info about process flow on AS
   3: get status of listening ports on AS
   4: get status of listening ports and httpd on DS
   5: device server idx setting on DS (/opt/smarts-ncm/data/devserver/our.idx)
 AS: Creation of command file by controldaemon on AS
   10: Pending jobs on AS for #{$cdm} (/opt/smarts-ncm/data/appserver/pops/pop#{$popnumber}/syssync/commmgr/toServer)
   11: Pending jobs on AS for all CDMs
   12: Pending jobs count on AS for all CDMs
   13: Move Pending jobs for a given CDM to amcdmconfig03 Backup Directory
   14: Last n lines of daemon.log
 AS: Syssyncd process on AS makes an https call to ssxfri.cgi on DS, to move the command file from AS to DS
   30: last n lines of syssyncm.log on AS
   31: search entries for a given job or popid (in syssyncm.log file)
   32: last n lines of ssxfrcgi.log on AS
   33: search entries for a given job or popid (in ssxfrcgi.log file)
   34: print any errors in ssxfrcgi in all AS
 DS: Status of command file transfered to DS, and executed on DS
   40: last n lines or search string in ssxfrcgi.log on DS
 DS: commmgrd executes the task files on DS
   41: Pending jobs on DS to be executed by commmgrd (File count in /opt/smarts-ncm/data/devserver/syssync/commmgr/toServer)
   42: tasks created for the command file execution on DS (/opt/smarts-ncm/data/devserver/syssync/commmgr/toMaster/deviceupdate)
   43: status and results from the execution of command file on DS (/opt/smarts-ncm/data/devserver/syssync/commmgr/toMaster/task)
   44: Pending jobs count on DS for all CDMs
 DS: Syssyncd process on DS moves the toMaster/task/taskstatus.xml and taskresult.xml files to AS (calling ssxfri.cgi on AS)
   50: last n lines of syssyncs.log on #{$cdm}
 AS: Status of results transferred from DS to AS
   60: search entries in ssxfri on AS (function needed)
 AS: Final stage before pushing data to Postgres database on AS
   61: command status/results files on AS for #{$cdm} (/opt/smarts-ncm/data/appserver/pops/pop#{$popnumber}/syssync/commmgr/toMaster/task)
 Restart NCM
   20: NCM services status
   21: status/start/stop NCM server
   22: kill specific PID on NCM server
 Syssyncd Status
   70: check if syssyncd is current on all AS
   71: check if syssyncd is current on all DS
   72: all CDMs where sshShadow file is not current
   73: all CDMs where Send complete is not done
   74: print any errors in ssxfrcgi in all CDMs
 GUI
  80: URL to start the GUI
  81: check for listening ports for GUI on AS (port 8880)
 EXIT Program
   9: Exit"
  case gets.strip
  when "0"
    Didatacommon.get_cdm
  when "1"
    Didatacommon.get_ncm_status
  when "2"
    Didatacommon.pending_jobs_AS_info
  when "3"
    puts "On the AS, the process syssyncd must be listening on port 9997"
    puts "if any connnection is in ESTABLISHED state, it indicates an error on the DS"
    Didatacommon.as_port_status
  when "4"
    puts "On the DS, the process syssyncd must be listening on port 9998"
    Didatacommon.ds_port_status
    Didatacommon.ds_httpd_status
  when "5"
    Didatacommon.ncm_ds_idx_setting
  when "20"
    Didatacommon.get_ncm_status_server
  when "21"
    Didatacommon.ncm_appserver_manage
  when "22"
    Didatacommon.ncm_kill_process
  when "10"
    Didatacommon.ncm_pending_jobs_AS_cdm
  when "11"
    Didatacommon.pending_jobs_AS_all
  when "12"
    Didatacommon.pending_jobs_count_AS_all
  when "13"
    Didatacommon.ncm_move_pending_jobs_to_backup
  when "14"
    Didatacommon.ncm_tail_daemon_AS
    puts " "
    puts "Current Time is:"+`date`
  when "30"
    Didatacommon.ncm_tail_syssyncm_AS
    puts " "
    puts "Current Time is:"+`date`
  when "31"
    Didatacommon.ncm_search_job_in_syssyncm_AS
    puts " "
    puts "Current Time is:"+`date`
  when "32"
    Didatacommon.ncm_tail_ssxfrcgi_AS
    puts " "
    puts "Current Time is:"+`date`
  when "33"
    Didatacommon.ncm_search_job_in_ssxfrcgi_AS
    puts " "
    puts "Current Time is:"+`date`
  when "34"
    Didatacommon.ncm_ssxfrcgi_errors_all_as
  when "40"
    Didatacommon.ncm_ssxfr_on_DS
  when "41"
    Didatacommon.ncm_pending_jobs_DS
  when "42"
    Didatacommon.ncm_tomaster_tasks_DS
  when "43"
    Didatacommon.ncm_tomaster_results_DS
  when "44"
    Didatacommon.pending_jobs_count_DS_all
  when "50"
    Didatacommon.ncm_tail_syssyncs_DS
    puts " "
    puts "Current Time is:"+`date`
  when "61"
    Didatacommon.ncm_tomaster_results_AS
  when "70"
    Didatacommon.ncm_syssyncd_is_current_all_as
  when "71"
    Didatacommon.ncm_syssyncd_is_current_all_ds
  when "72"
    Didatacommon.ncm_shadowfiles_not_getting_updated
  when "73"
    Didatacommon.ncm_missing_send_complete_all_ds
  when "74"
    Didatacommon.ncm_ssxfrcgi_errors_all_ds
  when "80"
    Didatacommon.ncm_gui_url
  when "81"
    Didatacommon.ncm_gui_port
  when "9"
    $menu=1
    puts "exiting..."
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
