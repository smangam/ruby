#!/usr/bin/ruby
#######################################
# program to delete cdm
# author: sunil mangam
#######################################

require '/root/smangam/didatacommon2'

$menu=0

def mainmenu
  puts "
 CDM Information
   0: enter CDM
 CDM Delete Steps
   1: check #{$cdm} is undeployed in ITSM - manual
   2: remove from hyperic - manual
 Remove from CALSAM, NCM App server
   10: get the CALSAM, NCM appserver for #{$cdm}
   11: remove #{$cdm} from Global Manager
   12: stop any running jobs for #{$cdm} in NCM GUI
 Stop Services on CDM
   20: stop sm_service on #{$cdm}
   21: stop crond on #{$cdm}
   22: stop APG
   23: stop NCM
   24: stop Hyperic Agent
 Shutdown VM
   30: power off CDM from vCenter
   31: delete the CDM from disk from vCenter
   32: remove/check dns entry
 Cleanup Puppet Manifests
   40: check entry in /etc/puppet/manifests/site.pp is removed
   41: check entry in /etc/puppet/environments/latest/hieradata/* files is removed
   42: remove puppet certificate for #{$cdm}
   43: check if the cdm is removed from calsam/cdlsam
   44: send email to Hierich to stop backups
   9: Exit"
  print "select an option:"
  case gets.strip
  when "0"
    Didatacommon.get_cdm
  when "1"
    print "search in ITSM CI for #{$cdm}"
  when "2"
    puts "Log into hyperic at http://am-ontrack-hyp03:7080 as hqadmin"
    puts "under Resources tab, search for the CDM, and then delete it"
  when "10"
    Didatacommon.get_cal
    Didatacommon.host_env($cdm)
  when "11"
    puts "Disable and delete the APM and OI domains from the CALSAM."
    puts "Login to the Global Manager Administration console and attach to the CALSAM."
    puts "ICS Configuration->IC Domain Configuration -> Domains." 
    puts "Click on the OI domain and Disable it on the right hand pane and hit reconfigure." 
    puts "Click on the APM domain and Disable it on the right hand pane and hit reconfigure."
    puts "Right click on the OI domain and delete and reconfigure."
    puts "Right click on the APM domain and delete and reconfigure"
  when "12"
    puts "login to the NCM App Server GUI"
    puts "stop any running jobs for the CDM"
  when "20"
    Didatacommon.sm_service_stop($cdm)
  when "21"
    Didatacommon.crond_stop
  when "22"
    Didatacommon.apg_stop
  when "23"
    Didatacommon.ncm_stop
  when "24"
    Didatacommon.hyperic_agent_stop
  when "32"
    Didatacommon.validate_dns
  when "40"
    Didatacommon.check_site_pp
  when "41"
    Didatacommon.get_cal
  when "42"
    Didatacommon.remove_puppet_cert
  when "43"
    Didatacommon.check_cdm_in_broker
  when "9"
    $menu=1 
  end
end

while $menu==0
  mainmenu
end

