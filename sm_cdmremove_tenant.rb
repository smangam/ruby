#!/usr/bin/ruby
#######################################
# program to delete cdm
# author: sunil mangam
#######################################

require '/root/smangam/didatacommon2'

$menu=0

def mainmenu
  puts "
 Base and Tenant CDM Information
   0: enter the base and tenant CDM
 Steps on tenant CDM
   1: stop all smarts services on #{$tenantcdm}
   2: remove all smarts services on #{$tenantcdm}
 Steps on the base CDM
   11: APG services status for #{$tenantcdm} on #{$basecdm}
   12: stop APG services for #{$tenantcdm} on #{$basecdm}
   13: remove all apg modules installed for #{$tenantcdm} from #{$basecdm}
   14: remove #{$tenantcdm} NCM dir from #{$basecdm}
   15: remove #{$tenantcdm} SMARTS dirs on #{$basecdm}
   16: stop #{$tenantcdm} smarts namespace on #{$basecdm}
   17: remove #{$tenantcdm} smarts namespace on #{$basecdm}
 Cleanup Puppet Manifests
   40: check entry in /etc/puppet/manifests/site.pp is removed
   41: check entry in /etc/puppet/environments/latest/hieradata/* files is removed
   42: remove puppet certificate for #{$cdm}
   43: check if the cdm is removed from calsam/cdlsam
   44: check #{$cdm} is undeployed in ITSM
   45: remove from hyperic
   9: Exit"
  print "select an option:"
  case gets.strip
  when "0"
    print "enter base cdm:"
    $basecdm=gets.chomp
    $cdm=$basecdm
    print "enter tenant cdm:"
    $tenantcdm=gets.chomp
  when "1"
    Didatacommon.tenant_sm_service_stop
  when "2"
    Didatacommon.tenant_sm_service_remove
  when "11"
    puts "run this command on the base cdm"
    Didatacommon.apg_service_status
  when "12"
    puts "run this command on the base cdm"
    Didatacommon.apg_service_manage
  when "13"
    Didatacommon.remove_tenant_apg_modules
  when "14"
    Didatacommon.remove_tenant_ncm_dir
  when "15"
    Didatacommon.remove_tenant_smarts_dir
  when "16"
    Didatacommon.tenant_sm_service_stop
  when "17"
    Didatacommon.tenant_sm_service_remove
  when "40"
    Didatacommon.check_site_pp
  when "41"
    Didatacommon.get_cal
  when "42"
    Didatacommon.remove_puppet_cert
  when "43"
    Didatacommon.check_cdm_in_broker
  when "42"
    puts "login to the NCM App Server GUI"
    puts "stop any running jobs for the CDM"
    puts "select the CDM, right-click, and delete the CDM"
  when "44"
    print "search in ITSM CI for #{$cdm}"
  when "45"
    puts "Log into hyperic at http://am-ontrack-hyp03:7080 as hqadmin"
    puts "under Resources tab, search for the CDM, and then delete it"
  when "16"
    print "Disable and delete the APM and OI domains from the CALSAM."
    print "Login to the Global Manager Administration console and attach to the CALSAM."
    print "ICS Configuration->IC Domain Configuration -> Domains." 
    print "Click on the OI domain and Disable it on the right hand pane and hit reconfigure." 
    print "Click on the APM domain and Disable it on the right hand pane and hit reconfigure."
    print "Right click on the OI domain and delete and reconfigure."
    print "Right click on the APM domain and delete and reconfigure"
  when "9"
    $menu=1 
  end
end

while $menu==0
  mainmenu
end

