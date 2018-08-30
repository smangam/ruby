#!/usr/bin/ruby

require '/root/smangam/didatacommon2'
$menu=0

def mainmenu
 puts "select an option
   0: enter CDM
   1: NCM services status
 NCM Postgresql DB Server (controldb) Information
   10: check if a given DS exists in the Postgresql database
   11: check if a given POP ID exists in the Postgresql database
   12: check for duplicate DS entries in the Postgresql database
   13: delete DS from Postgresql database
   14: list networks from controldb on #{$ncm_dbserver}
   15: get network for a given network id from controldb
   16: enter sql query
   17: current active queries in controldb
   18: list devices for #{$cdm} in controldb
   19: list device pull data for #{$cdm} in controldb
 NCM Infra Database (cflist) on AS
   20: check if #{$cdm} exists correctly in the Infra database
   21: check if duplicate IPs are assigned to device servers in Infra database
   22: get device server for a given POP ID
   22a: check if incorrect entries exist in the Infra database
   23: cleanup Infra database, if duplicate entries exist for #{$cdm}
   24: list all device data from NCM Infra database for #{$cdm}
   25: get specific device data from NCM Infra database
   26: list devices by sysobjectid in Infra database
   27: list undeployed CDMs that still exist in Infra Database
 NCM Infra Database on DS
   30: get local infradb contents on DS for #{$cdm}
   31: modify local infradb contents on DS for #{$cdm}
 Voyence Config Download Report
   40: get database entry for #{$cdm} as used in the Voyence Config Download Report
 Check POP ID Consistency
   50: check POP ID consistency across AS and DS for all CDMs in ControlDB
   51: check POP ID consistency across AS and DS for all CDMs in InfraDB
 EXIT Program
   9: Exit"
  case gets.strip
  when "0"
    Didatacommon.get_cdm
  when "1"
    Didatacommon.get_ncm_status
  when "10"
    print "enter DS(cdm) to check (example, am-goldcorp):"
    ds=gets.chomp.upcase
    Didatacommon.ncm_find_cdm_in_controldb(ds)
  when "11"
    Didatacommon.ncm_find_pop_in_controldb
  when "12"
    Didatacommon.check_ds_duplicates_in_controldb
  when "13"
    Didatacommon.ncm_delete_ds_from_controldb
  when "14"
    Didatacommon.list_networks_from_controldb
  when "15"
    Didatacommon.get_network_from_controldb
  when "16"
    Didatacommon.postgresql_simple_query
  when "17"
    Didatacommon.ncm_controldb_list_active_queries
  when "18"
    Didatacommon.get_device_list_from_controldb
  when "19"
    Didatacommon.get_device_pulldata_from_controldb
  when "20"
    Didatacommon.ncm_get_cdm_popnumber($cdm) 
  when "21"
    Didatacommon.ncm_check_ip_infradb 
  when "22"
    Didatacommon.ncm_get_ds_for_popid_infradb 
  when "22a"
    Didatacommon.ncm_check_infradb 
  when "23"
    Didatacommon.cleanup_infradb 
  when "24"
    Didatacommon.list_devices_for_ds_infradb
  when "25"
    Didatacommon.get_device_from_infradb
  when "26"
    Didatacommon.find_devices_in_infradb
  when "27"
    Didatacommon.ncm_list_obsolete_ds_in_infradb
  when "30"
    Didatacommon.print_cflist_ds
  when "31"
    Didatacommon.cleanup_ds_infradb
  when "40"
    Didatacommon.get_cdm_entry_from_CDMsOnVoyence
  when "50"
    Didatacommon.ncm_check_pop_id_all_in_controldb
  when "51"
    Didatacommon.ncm_check_pop_id_all_in_infradb
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
