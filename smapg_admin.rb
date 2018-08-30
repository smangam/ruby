#!/usr/bin/ruby

require '/root/smangam/didatacommon2'
$menu=0  
$backend_host="amcalapgbkend03"

def myMenu
 puts "Choose an option:
   0: Update CDM APG Database list
   1: List APG database hosts
   2: List APG databases on a given host 
   3: List APG Backends
 APG CDM (Collecting component)
   10: Enter CDM
   11: Raw data backlog for #{$cdm} (when collected raw data cannot be sent to the Backend, files are stored here)
   12: Raw data backlog for all CDMs
   13: APG service status for #{$cdm}
   14: APG service start/stop for #{$cdm}
   15: list connectors on #{$cdm}
   16: socket connection status between #{$cdm} and Backend
 APG CDM Disk Space Management
   40: show disk space status for #{$cdm}
   41: list APG CDMs where /opt is >99% full
   42: list files in a given directory for #{$cdm}
   43: move files to manage space for #{$cdm}
   44: manage qdf files to manage space for #{$cdm}
   45: manage qdf files to manage space for all CDMs
 APG Backend (the Processing component)
   20: Enter APG Backend host (amcalapgbkend02,3,4)
   21: about processing component (takes raw data from collecting component,aggregates and sends to MySQL db)
   22: APG service status for #{$apg_cdm_backend_host}
   23: APG service start for #{$apg_cdm_backend_host}
   24: Backend instances/ports on #{$backend_host}
   25: CDMs assigned to backend #{$backend_host}
   26: list of socket connections between CDMs and Backend on #{$backend_host}
   27: status of temp directory on #{$backend_host} (aggregated data is stored here, before sending to MySQL database)
   28: details of MySQL database to which processing component sends data
 APG Database Server
   30: Enter APG Database host (amcalapgdb01,2,3,4,5,6,7)
   31: Execute an SQL statement
   32: Total database size
   33: Show running threads (show processlist) on the server
   34: Show processes running LOAD DATA across all servers
 APG Software Version Checks
   50: Check version of Availability Filter on all CDMs
 APG Database Server Load File List
   99: Exit"
 case gets.strip
 when "0"
   Didatacommon.get_db_cdm_list_apg
 when "1"
   puts $dbhost_array
 when "2"
   Didatacommon.get_databases_on_dbhost
 when "3"
   Didatacommon.apg_list_backends
 when "10"
   Didatacommon.get_cdm
   $backend_host=$apg_cdm_backend_host
 when "11"
   Didatacommon.apg_cdm_failover_filter_status
 when "12"
   Didatacommon.apg_cdm_failover_filter_status_all
 when "13"
   Didatacommon.apg_service_status
 when "14"
   Didatacommon.apg_service_manage
 when "15"
   Didatacommon.apg_cdm_list_connectors
 when "16"
   Didatacommon.apg_cdm_backend_socket_connection
 when "40"
   Didatacommon.fs_status
 when "41"
   Didatacommon.apg_fs_status_all
 when "42"
   Didatacommon.apg_list_files
 when "43"
   Didatacommon.apg_move_files
 when "44"
   Didatacommon.apg_manage_qdf_files($cdm)
 when "45"
   Didatacommon.apg_manage_qdf_files_all
 when "20"
   print "enter backend host:"
   $backend_host=gets.chomp
 when "22"
   Didatacommon.apg_service_status
 when "23"
   Didatacommon.apg_service_manage
 when "24"
   Didatacommon.apg_backend_instances($backend_host)
 when "25"
   Didatacommon.apg_cdms_on_backend($backend_host)
 when "26"
   Didatacommon.backend_socket_connections($backend_host)
 when "27"
   Didatacommon.backend_tmpdir_status($backend_host)
 when "28"
   Didatacommon.apg_backend_mysql_info($backend_host)
 when "30"
   puts $db_hash
   print "enter database host:"
   $db_host=gets.chomp
   print "enter database:"
   $apgdb=gets.chomp
 when "31"
   Didatacommon.exec_sql
 when "32"
   Didatacommon.get_db_size
 when "33"
   Didatacommon.get_dbserver_processlist
 when "34"
   Didatacommon.get_dbserver_processlist_load_all
 when "50"
   Didatacommon.apg_cdm_availability_filter_check_version_all
 when "99"
   $menu=1
   print "exiting..."
 end
end

############################
# main program
############################
Didatacommon.get_dblist_apg

while $menu==0
  myMenu
  #if $cdm != nil
  #  puts "CDM is #{$cdm}"
  #else
  # Didatacommon.get_cdm
  # $backend_host=$apg_cdm_backend_host
  #end
end
