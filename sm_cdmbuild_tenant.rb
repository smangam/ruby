#!/usr/bin/ruby
#######################################
# program to configure new multi-t cdm
# author: sunil mangam
#######################################

require '/root/smangam/didatacommon'

$menu=0

def insert_into_mysql
  print "enter #{$tenantcdm} internal ip address (#{$tenant_int_ip}):"
  $tenant_int_ip=gets.chomp
  $dbhost="amcalidm01"
  $mysql="/opt/ddam/mysql-5.7.13/bin/mysql"
  $sqlesc="\'\"\'\"\'"
  sql='"' + "select count(*) from MultiTenants where Tenant=#{$sqlesc}#{$tenantcdm}#{$sqlesc} ;" +'"'
  cmd="ssh root@#{$dbhost} "+"'"+" #{$mysql} -h #{$dbhost} -u root -e " +sql+" RIM -B -N"+"'"
  row_count = `#{cmd}`.chomp
  if row_count=='0'
    puts "inserting new row.."
    sql='"' + "insert into MultiTenants(BaseHost,Tenant,TenantIP,Active) values(#{$sqlesc}#{$basecdm}#{$sqlesc},#{$sqlesc}#{$tenantcdm}#{$sqlesc} ,#{$sqlesc}#{$tenant_int_ip}#{$sqlesc},1) ;" +'"'
    cmd="ssh root@#{$dbhost} "+"'"+" #{$mysql} -h #{$dbhost} -u root -e " +sql+" RIM -B -N"+"'"
    output=`#{cmd}`
    puts output
  else
    puts "did not insert"
  end
end

def remove_ncf_files
  cmd="ssh root@#{$basecdm} ls /opt/InCharge9/SAM/smarts/global/conf/icoi/*ncf"
  puts cmd
  system("#{cmd}")
  if $?.exitstatus==0
    puts "ncf files exist"
    cmd="ssh root@#{$basecdm} rm -rf /opt/InCharge9/SAM/smarts/global/conf/icoi/*ncf"
    puts cmd
    system("#{cmd}")
    if $?.exitstatus==0
      puts "ncf files deleted"
    end
  else
   puts "ncf files do not exist"
  end
end

def create_softlink_icoi
  cmd="ssh root@#{$basecdm} ln -s /opt/InCharge9/SAM/smarts/customer/#{$tenantcdm}/conf/icoi /opt/InCharge9/SAM/smarts/regional/conf/icoi/#{$tenantcdm}"
  puts cmd
  system("#{cmd}")
  if $?.exitstatus==0
    puts "softlink created successfully"
  else
   puts "softlink creation failed"
  end
end

def copy_running_ncf
  cmd="scp amcdmconfig02:/etc/puppet/regional/modules/amrimcdm/files/running.ncf #{$basecdm}:/opt/InCharge9/SAM/smarts/customer/#{$tenantcdm}/conf/icoi/#{$tenantcdm}_running.ncf"
  puts cmd
  system("#{cmd}")
  if $?.exitstatus==0
    puts "copy successful"
  else
   puts "copy failed"
  end
end

def copy_RIM_ForcedManagementStatus
   cmd="ssh root@#{$basecdm} ls /opt/InCharge9/IP/smarts/regional/conf/discovery/RIM_ForcedManagementStatus.conf"
   if !system("#{cmd}")
     cmd="ssh root@#{$basecdm} touch /opt/InCharge9/IP/smarts/regional/conf/discovery/RIM_ForcedManagementStatus.conf"
     system("#{cmd}")
   end

   cmd="ssh root@#{$basecdm} ls /opt/InCharge9/IP/smarts/regional/conf/discovery/RIM_ForcedManagementStatus.conf"
   if system("#{cmd}")
    puts "success: #{cmd}"
    cmd="ssh root@#{$basecdm} ln -s /opt/InCharge9/IP/smarts/regional/conf/discovery/RIM_ForcedManagementStatus.conf /opt/InCharge9/IP/smarts/customer/#{$tenantcdm}/conf/discovery/RIM_ForcedManagementStatus.conf"
    if system("#{cmd}")
      puts "success: #{cmd}"
    else
      puts "fail: #{cmd}"
    end
   else
    puts "fail: #{cmd}"
   end
end

def cronjob
  cmd="sed '" +"s/am-template/#{$tenantcdm}/g" +"' am-template_amcdm-crontab > /root/smangam/#{$tenantcdm}_amcdm-crontab"
  puts cmd
  system("#{cmd}")
  cmd="scp /root/smangam/#{$tenantcdm}_amcdm-crontab  root@#{$basecdm}:/etc/cron.d"
  if system("#{cmd}")
    puts "success: #{cmd}"
  else
    puts "fail: #{cmd}"
  end
end

def disable_RIMTroubleTicketID_Driver
  cmd="ssh root@#{$basecdm} sed -i 's/^call/#call/' /opt/InCharge9/SAM/smarts/customer/#{$tenantcdm}/conf/icoi/RIM_TroubleTicketID.import"
  puts cmd
  if system("#{cmd}")
    puts "disable success"
  else
    puts "disable failed"
  end
  cmd="ssh root@#{$basecdm} dmctl -s AMCDM_#{$TENANTCDM}_ADAPTER_OI invoke GA_DaemonDriver::RIM-TroubleTicketID-Driver stop"
  puts cmd
  if system("#{cmd}")
    puts "disable success"
  else
    puts "disable failed"
  end
end

def add_tenant_to_documentserver
  cmd="ssh root@amcdldoc01 /opt/rim/webapps/RIMdocs/directory_creator.pl #{$TENANTCDM}"
  puts cmd
  if system("#{cmd}")
    puts "success"
  else
    puts "failed"
  end
end

def edit_logrotate
  cmd="scp /root/smangam/sm_logrotate.sh root@#{$basecdm}:/tmp"
  if system("#{cmd}")
    puts "success: #{cmd}"
    cmd="ssh root@#{$basecdm} /tmp/sm_logrotate.sh"
    if system("#{cmd}")
      puts "success: #{cmd}"
    else
      puts "fail: #{cmd}"
    end
  else
    puts "fail: #{cmd}"
  end
end

def apg_ncm_status
  cmd="ssh root@#{$basecdm} /opt/APG/bin/manage-modules.sh service status all"
  output=`#{cmd}`
  puts output
  cmd="ssh root@#{$basecdm} systemctl status vcmaster.service"
  output=`#{cmd}`
  puts output
  cmd="ssh root@#{$basecdm} brcontrol|grep -i #{$tenantcdm}"
  puts `#{cmd}`
end

def puppet_agent_run
  print "login to #{$basecdm} and execute the following:"
  cmd="time puppet agent --test 2>&1 | tee /var/log/puppet/#{$tenantcdm}.log.1"
  puts cmd
end

def copy_ssh
  cmd="ssh-copy-id root@#{$tenantcdm}"
  if system("#{cmd}")
   puts "successful"
  end
end

def add_static_route
  cmd="ssh root@#{$basecdm} /opt/rim/scripts/add-base2tenant-cust-interface-route.sh #{$tenantcdm}"
  puts cmd
  puts `#{cmd}`
end

def mainmenu
  puts "
 CDM Information
   0: enter base and tenant CDM
   1: enter tenant CDM IP address and other details
 Pre Puppet Run Tasks
   10: add internal (152.x) IP address to DNS server (2 entries)
   11: validate dns entries
   12: add an interface card for each multiT CDM in vCenter
   13: get interface names for the newly added network cards
   14: create tenant stub for site.pp
   15: validate /etc/puppet/manifests/site.pp file
   16: edit/validate #{$hieradata_node_dir}/#{$basecdm}.us.gsoa.local.yaml file
 Puppet Run
   17: execute puppet run
   18: set connected and connection on power for interfaces in vCenter
   19: copy ssh keys
 Tenant Configuration
   20: configure SNMP collector (once per Tenant CDM)
   21: start/stop/show sm_service on tenant (once per Tenant CDM)
   22: add static route (once per Tenant CDM)
   23: create softlink for icoi (once per Tenant CDM)
   24: copy running.ncf from config server (once per Tenant CDM)
   25: copy RIM_ForcedManagementStatus (once per Tenant CDM)
   26: create cron job (once per Tenant CDM)
   27: disable_RIMTroubleTicketID_Driver (once per Tenant CDM)
   28: add_tenant_to_documentserver (once per Tenant CDM)
   29: update logrotate (once per Tenant CDM)
   30: insert into mysql database
   g: update system limits in SMARTS APM (per Tenant CDM)
   h: update IDM NOTIF (per Tenant CDM)
 Deploy in DEPSAM
   40: check where a cdm is deployed
   41: add/edit #{$hieradata_node_dir}/amcalsamdep01.us.gsoa.local.yaml to deploy into deployments
   42: run puppet
 Checks
   50: check apg and vcmaster
   99: Exit"
  print "select an option:"
  case gets.strip
  when "0"
    Didatacommon.get_tenant
  when "1"
    Didatacommon.tenant_details
  when "11"
    Didatacommon.validate_dns
  when "13"
    Didatacommon.get_interface_names
  when "14"
    Didatacommon.create_sitepp_stub
  when "15"
    Didatacommon.validate_basecdm_site_pp
  when "16"
    Didatacommon.validate_basecdm_yaml
  when "17"
    puts "login to #{$basecdm} and execute the following:"
    cmd="puppet agent --test 2>&1 | tee /var/log/puppet/#{$tenantcdm}.log.1"
    puts cmd
  when "19"
    copy_ssh
  when "20"
    Didatacommon.copy_snmp_collector 
  when "21"
    Didatacommon.sm_service
  when "22"
    add_static_route
  when "23"
    create_softlink_icoi
  when "24"
    copy_running_ncf 
  when "25"
    copy_RIM_ForcedManagementStatus
  when "26"
    cronjob
  when "27"
    disable_RIMTroubleTicketID_Driver
  when "28"
    add_tenant_to_documentserver
  when "29"
    edit_logrotate
  when "30"
    insert_into_mysql
  when "40"
    Didatacommon.where_cdm_is_deployed
  when "41"
    puts "add entries to the yaml file"
    puts "ssh to amcalsamdep01 and execute: time puppet agent --test 2>&1 | tee /var/log/puppet/#{$tenantcdm}.log.1 "
  when "42"
    print "enter host where you want to deploy(amcalsam04,amcalsamdep01,amcalsam05,etc):"
    myhost=gets.chomp
    cmd="ssh root@#{myhost} puppet agent --test 2>&1 | tee /var/log/puppet/deployment.log.1"
    puts cmd
    puts `#{cmd}`
  when "50"
    apg_ncm_status
  when "99"
    $menu=1 
  end
end

while $menu==0
  mainmenu
end

