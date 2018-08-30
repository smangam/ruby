#!/usr/bin/ruby
#######################################
# program to configure new multi-t base cdm
# author: sunil mangam
#######################################

require '/root/smangam/didatacommon'

$menu=0

def apg_ncm_status
  cmd="ssh root@#{$basecdm} /opt/APG/bin/manage-modules.sh service status all"
  output=`#{cmd}`
  puts output
  cmd="ssh root@#{$basecdm} systemctl status vcmaster.service"
  output=`#{cmd}`
  puts output
end

def mainmenu
  puts "
 CDM Information
   0: enter base CDM
 vCenter Tasks
   1: add internal (152.x) IP address of the base CDM to DNS server (1 entry: example am-cdmMulti3.us.gsoa.local)
   2: validate dns entries
   3: build a VM for #{$basecdm}
   4: add network cards to the VM
   5: power on VM
   6: from base CDM Console, execute /opt/rim/scripts/assign-ip.sh
   7: list interfaces on #{$basecdm}
 Pre Puppet Run Tasks
   10: create a new file #{$hieradata_node_dir}/#{$basecdm}.us.gsoa.local.yaml
   11: edit #{$hieradata_node_dir}/#{$basecdm}.us.gsoa.local.yaml file
   12: validate #{$hieradata_node_dir}/#{$basecdm}.us.gsoa.local.yaml file
   13: edit #{$site_pp_path} and add a #{$basecdm} node stanza
   14: validate site.pp file
 Puppet Run
   h: execute on #{$basecdm} 3 times: time puppet agent --test 2>&1 | tee /var/log/puppet/cdm94.log.1
   i: enable amrimcdm-multi in #{$hieradata_node_dir}/#{$basecdm}.us.gsoa.local.yaml
   j: execute on #{$basecdm}: puppet agent --test --tags amrimcdm-multi 2>&1 | tee /var/log/puppet/cdm94.log.4
   k: enable amncmdrivers::install in #{$hieradata_node_dir}/#{$basecdm}.us.gsoa.local.yaml
   l: execute on #{$basecdm}: puppet agent --test --tags amncmdrivers 2>&1 | tee /var/log/puppet/cdm94.log.5
   m: enable hqagent-cdm::install in #{$hieradata_node_dir}/#{$basecdm}.us.gsoa.local.yaml
   n: execute on #{$basecdm}: puppet agent --test --tags hqagent-cdm 2>&1 | tee /var/log/puppet/cdm94.log.6
 Other Configuration
   20: copy modified routes
   21: unlock ncm lockbox
   22: copy custom APM certification file
   23: remove notif packages
   24: update firewall rules
   25: start/stop/show sm_service on base CDM
 Post Installation
   50: In vCenter VM, edit and add - [autostart:yes][linux:backup][DR:replicated]
   99: Exit"
  print "select an option:"
  case gets.strip
  when "0"
    Didatacommon.get_base_cdm
  when "1"
    Didatacommon.add_dns_entry_solo_help
  when "2"
    Didatacommon.validate_dns
  when "3"
    Didatacommon.build_VM_help
  when "4"
    Didatacommon.VM_networkcards_help
  when "7"
    Didatacommon.list_interface_names
  when "10"
    Didatacommon.create_basecdm_yaml
  when "12"
    Didatacommon.validate_basecdm_yaml
  when "13"
    Didatacommon.site_pp_stanza
  when "14"
    Didatacommon.validate_basecdm_site_pp
  when "20"
    Didatacommon.basecdm_copy_modified_routes
  when "21"
    Didatacommon.ncm_unlock_lockbox
  when "22"
    Didatacommon.basecdm_copy_custom_apm_certifications
  when "23"
    Didatacommon.basecdm_remove_ncf_files
  when "24"
    Didatacommon.basecdm_update_firewall_rules
  when "25"
    Didatacommon.sm_service
  when "99"
    $menu=1 
  end
end

while $menu==0
  mainmenu
end

