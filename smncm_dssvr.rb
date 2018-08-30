#!/usr/bin/ruby
###############################
# author: sunil mangam
# this script is used for NCM TS
###############################
require '/root/smangam/didatacommon2'
$menu=0

def mainmenu
 puts "select an option
   0: enter CDM
   1: NCM services status
   4: get status of listening ports and httpd on DS
   5: device server idx setting on DS (/opt/smarts-ncm/data/devserver/our.idx)
 DS Device Driver Health
   10: notes about device driver compilation
   11: check for device drivers compile status
   12: check device drivers
 Restart NCM
   20: NCM services status
   21: status/start/stop NCM server
   22: kill specific PID on NCM server
 GUI
  70: URL to start the GUI
  71: check for listening ports for GUI on AS (port 8880)
 EXIT Program
   9: Exit"
  case gets.strip
  when "0"
    Didatacommon.get_cdm
  when "1"
    Didatacommon.get_ncm_status
  when "4"
    puts "On the DS, the process syssyncd must be listening on port 9998"
    Didatacommon.ds_port_status
    Didatacommon.ds_httpd_status
  when "5"
    Didatacommon.ncm_ds_idx_setting
  when "10"
    Didatacommon.ncm_ds_device_driver_notes
  when "11"
    Didatacommon.ncm_ds_device_driver_compile_status
  when "12"
    Didatacommon.ncm_check_device_drivers
  when "20"
    Didatacommon.get_ncm_status_server
  when "21"
    Didatacommon.ncm_appserver_manage
  when "22"
    Didatacommon.ncm_kill_process
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
