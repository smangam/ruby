#!/usr/bin/ruby
#######################################
# program to configure new solo cdm
# author: sunil mangam
#######################################

$menu=0
$puppet_env="branches_RIM_9_4_1_0"

def get_cdm
  print "enter cdm:"
  $cdm=gets.chomp
  $CDM=$cdm.upcase
  $cdm_fqdn="#{$cdm}.us.gsoa.local"
end

def copy_snmp_collector
  cmd="ssh root@#{$basecdm} cp /opt/APG/Collecting/SNMP-Collector/#{$tenantcdm}/conf/snmp-polling-distribution-empty.xml /opt/APG/Collecting/SNMP-Collector/#{$tenantcdm}/conf/snmp-polling-distribution.xml"
  system("#{cmd}")
  if $?.exitstatus==0
    puts "snmp-polling-distribution.xml copy successful"
  else
   puts "snmp-polling-distribution.xml copy failed"
  end
  cmd="ssh root@#{$tenantcdm} /opt/rim/scripts/install-custom-apg-snmpC-MultiT.sh"
  puts cmd
  system("#{cmd}")
  if $?.exitstatus==0
    puts "snmp config successful"
    cmd="ssh root@#{$basecdm} ls -ltr /var/log/custom-snmpC-install.log"
    output=`#{cmd}`
    puts output
    cmd="ssh root@#{$basecdm} cat /var/log/custom-snmpC-install.log"
    output=`#{cmd}`
    puts output
  else
   puts "snmp config failed"
  end
end

def sm_service_status
  puts "SMARTS service status. enter start --all,stop --all, show:"
  option=gets.chomp
  cmd="ssh root@#{$cdm} sm_service #{option}" 
  puts cmd
  output=`#{cmd}`
  puts output
end

def apg_status
  puts "APG service status. enter start all,stop all, status all:"
  option=gets.chomp
  cmd = "ssh root@#{$cdm} /opt/APG/bin/manage-modules.sh service #{option}"
  puts `#{cmd}`
end

def ncm_status
  puts "NCM status. enter start, stop, status:"
  option=gets.chomp
  if option == 'status'
    puts "status of sysadmin"
    cmd="ssh root@#{$cdm} systemctl status sysadmin"
    puts `#{cmd}`
    cmd="ssh root@#{$cdm} ps -eaf|grep sysmon"
    puts `#{cmd}`
    puts "status of NCM services"
    cmd="ssh root@#{$cdm} ps -eaf|grep voyence"
    puts `#{cmd}`
    print "enter voyence pid:"
    pid=gets.chomp
    cmd="ssh root@#{$cdm} ps -eaf|grep #{pid}"
    puts `#{cmd}`
    cmd="ssh root@#{$cdm} netstat -anp|grep 999"
    puts `#{cmd}`
  elsif option == 'stop'
    puts "stopping sysadmin"
    cmd="ssh root@#{$cdm} systemctl stop sysadmin"
    puts `#{cmd}`
    cmd="scp /root/smangam/ncmstop.sh root@#{$cdm}:/root"
    if system("#{cmd}")
      puts "stopping NCM services"
      cmd="ssh root@#{$cdm} /root/ncmstop.sh"
      puts `#{cmd}`
    else
      puts "fail: #{cmd}"
    end
  elsif option == 'start'
    puts "starting NCM services"
    cmd="scp /root/smangam/ncmstart.sh root@#{$cdm}:/root"
    if system("#{cmd}")
      puts "starting NCM services"
      cmd="ssh root@#{$cdm} /root/ncmstart.sh"
      puts `#{cmd}`
    else
      puts "fail: #{cmd}"
    end
  end
end

def add_cdm_to_documentserver
  cmd="ssh root@amcdldoc01 /opt/rim/webapps/RIMdocs/directory_creator.pl #{$CDM}"
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

def smarts_apg_ncm_status
  cmd="ssh root@#{$cdm} sm_service show"
  puts `#{cmd}`
  cmd="ssh root@#{$cdm} /opt/APG/bin/manage-modules.sh service status all"
  puts `#{cmd}`
  cmd="ssh root@#{$cdm} systemctl status vcmaster.service"
  puts `#{cmd}`
  cmd="ssh root@#{$cdm} brcontrol|grep -i #{$cdm}"
  puts `#{cmd}`
end

def get_interface_names
  puts "the newly created interfaces have a state of DOWN and do not have IP address assigned"
  cmd="ssh root@#{$basecdm} ip a s"
  puts `#{cmd}`
end

def edit_sitepp
  puts "add the following to /etc/puppet/manifests/site.pp"
  puts "node '"+"#{$cdm_fqdn}"+"' {"
  puts "class { 'general': stage => 'pre' }"
  puts "}"
end

def validate_sitepp
  cmd="cp /etc/puppet/manifests/site.pp /root/smangam"
  system("#{cmd}")
  cmd="grep -A3 #{$cdm} /root/smangam/site.pp" 
  puts `#{cmd}` 
end

def create_cdm_hierayaml
  #puts "comment out hqagent-cdmMultiT, amrimcdm-multi and amncmdrivers classes in the basecdm yaml file"
  cmd="ls -ltr /etc/puppet/environments/#{$puppet_env}/hieradata/node/#{$cdm_fqdn}.yaml 2>/dev/null"
  if system("#{cmd}")
    puts "#{$cdm_fqdn}.yaml file already exists"
    cmd="cp /etc/puppet/environments/#{$puppet_env}/hieradata/node/#{$cdm_fqdn}.yaml /root/smangam/#{$cdm_fqdn}.yaml"
    puts `#{cmd}`
  else
    puts "#{$cdm_fqdn} heira yaml file does not exist. creating one"
    #cmd="cp /etc/puppet/environments/#{$puppet_env}/hieradata/node/am-txdot.us.gsoa.local.yaml /etc/puppet/environments/#{$puppet_env}/hieradata/node/#{$cdm}.us.gsoa.local.yaml"
    #puts `#{cmd}`
    cmd="cp /etc/puppet/environments/#{$puppet_env}/hieradata/node/am-txdot.us.gsoa.local.yaml /root/smangam/#{$cdm_fqdn}.yaml"
    puts `#{cmd}`
  end
end

def update_cdm_hierayaml
  puts "updating the cdm hiera yaml file"
  cmd="sed -i "+"'"+"s/ipaddress:\s*[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*/ipaddress: #{$cdm_ext_ip}/"+"'"+" /root/smangam/#{$cdm}.us.gsoa.local.yaml"
  `#{cmd}`
  cmd="sed -i "+"'"+"s/network:\s*172.*/network: #{$cdm_ext_network}/"+"'"+" /root/smangam/#{$cdm_fqdn}.yaml"
  `#{cmd}`
  cmd="sed -i "+"'"+"s/0.0.0.0\\/0:.*/0.0.0.0\\/0: #{$cdm_ext_gateway}/"+"'"+" /root/smangam/#{$cdm_fqdn}.yaml"
  `#{cmd}`
  cmd="sed -i "+"'"+"s/rimcdm::ncm_app_server_host:\s*.*/rimcdm::ncm_app_server_host: #{$cdm_ncm_host}/"+"'"+"  /root/smangam/#{$cdm_fqdn}.yaml"
  `#{cmd}`
  cmd="sed -i "+"'"+"s/rimcdm::ncm_app_server_ip:\s*.*/rimcdm::ncm_app_server_ip: #{$cdm_ncm_host_ip}/"+"'"+" /root/smangam/#{$cdm_fqdn}.yaml"
  `#{cmd}`
  cmd="sed -i "+"'"+"s/rimcdm::apg_backend_host:\s*.*/rimcdm::apg_backend_host: #{$cdm_apg_backend_host}/"+"'"+" /root/smangam/#{$cdm_fqdn}.yaml"
  `#{cmd}`
  cmd="sed -i "+"'"+"s/rimcdm::apg_backend_port:\s*.*/rimcdm::apg_backend_port: #{$cdm_apg_backend_port}/"+"'"+" /root/smangam/#{$cdm_fqdn}.yaml"
  `#{cmd}`
  cmd="sed -i "+"'"+"s/rimcdm::rim_tag:\s*.*/rimcdm::rim_tag: #{$cdm}/"+"'"+" /root/smangam/#{$cdm_fqdn}.yaml"
  `#{cmd}`
end

def copy_cdm_hierayaml
  cmd="cat /root/smangam/#{$cdm_fqdn}.yaml"
  puts `#{cmd}`
  print "is it ok to keep this file?(y/n):"
  resp=gets.chomp
  if resp == 'y'
    cmd="cp /root/smangam/#{$cdm_fqdn}.yaml /etc/puppet/environments/#{$puppet_env}/hieradata/node/#{$cdm_fqdn}.yaml" 
    puts `#{cmd}`
    cmd="cat /etc/puppet/environments/#{$puppet_env}/hieradata/node/#{$cdm_fqdn}.yaml"
    puts `#{cmd}`
  end
end

def validate_cdm_hierayaml
  cmd="cat /etc/puppet/environments/#{$puppet_env}/hieradata/node/#{$cdm_fqdn}.yaml"
  puts `#{cmd}`
end

def validate_dns
  cmd="nslookup #{$cdm}"
  puts `#{cmd}` 
  print "enter CDM ip address:"
  ip=gets.chomp
  cmd="nslookup #{ip}"
  puts `#{cmd}` 
end

def puppet_agent_run
  print "enter run number:"
  mynum=gets.chomp
  cmd="ssh root@#{$cdm} puppet agent --test 2>&1 | tee /var/log/puppet/#{$cdm}.log.#{mynum}"
  puts `#{cmd}`
end

def get_cdm_details
  print "enter #{$cdm} internal ip address ( 152.110.240.xx ):"
  $cdm_int_ip=gets.chomp
  $cdm_int_mask="255.255.255.0"
  print "enter #{$cdm} external ip address ( 172.18.xx.254 ):"
  $cdm_ext_ip=gets.chomp
  oct1,oct2,oct3,oct4 = $cdm_ext_ip.split('.')
  $cdm_ext_mask="255.255.255.128"
  print "enter #{$cdm} external gateway address ( #{oct1}.#{oct2}.#{oct3}.129 ):"
  $cdm_ext_gateway=gets.chomp
  print "enter #{$cdm} external network address ( #{oct1}.#{oct2}.#{oct3}.0 ):"
  $cdm_ext_network=gets.chomp
  print "enter #{$cdm} NCM host ( amcdlncmapp01/02/03/04 ):"
  $cdm_ncm_host=gets.chomp
  if $cdm_ncm_host == "amcdlncmapp01"
    $cdm_ncm_host_ip="152.110.242.30"
  elsif $cdm_ncm_host == "amcdlncmapp02" 
    $cdm_ncm_host_ip="152.110.242.31"
  elsif $cdm_ncm_host == "amcdlncmapp03"
    $cdm_ncm_host_ip="152.110.242.32"
  elsif $cdm_ncm_host == "amcdlncmapp04"
    $cdm_ncm_host_ip="152.110.242.33"
  end
  print "enter #{$cdm} NCM host ip( #{$cdm_ncm_host_ip} ):"
  $cdm_ncm_host_ip=gets.chomp
  print "enter #{$cdm} APG backend host (amcalapgbkend01/02/03):"
  $cdm_apg_backend_host=gets.chomp
  print "enter #{$cdm} APG backend port (3000,3500,etc):"
  $cdm_apg_backend_port=gets.chomp
  puts "cdm details:"
  puts "cdm internal ip address: #{$cdm_int_ip}"
  puts "cdm internal ip mask   : #{$cdm_int_mask}"
  puts "cdm external ip address: #{$cdm_ext_ip}"
  puts "cdm external ip mask   : #{$cdm_ext_mask}"
  puts "cdm external gateway   : #{$cdm_ext_gateway}"
  puts "cdm ncm host and ip    : #{$cdm_ncm_host} #{$cdm_ncm_host_ip}"
  puts "cdm apg bknd host/port : #{$cdm_apg_backend_host} #{$cdm_apg_backend_port}"
end

def ncm_unlock_lockbox
  cmd="ssh root@#{$cdm} /opt/rim/scripts/unlock_ncm_lockbox.sh"
  if system("#{cmd}")
    puts "success: #{cmd}"
  else
    puts "fail: #{cmd}"
  end
end

def copy_running_ncf
  cmd="scp amcdmconfig02:/etc/puppet/regional/modules/amrimcdm/files/running.ncf #{$cdm}:/opt/InCharge9/SAM/smarts/regional/conf/icoi/running.ncf"
  puts cmd
  system("#{cmd}")
  if $?.exitstatus==0
    puts "copy successful"
    cmd="ssh root@#{$cdm} ls -ltr /opt/InCharge9/SAM/smarts/regional/conf/icoi/running.ncf"
    puts `#{cmd}`
  else
   puts "copy failed"
  end
end

def copy_custom_apm_certifications
  cmd="scp amcdmconfig02:/etc/puppet/regional/modules/amrimcdm/files/oid2type_Field.conf #{$cdm}:/opt/InCharge9/IP/smarts/regional/conf/discovery/oid2type_Field.conf"
  if system("#{cmd}")
    puts "success: #{cmd}"
  else
    puts "fail: #{cmd}"
  end
  cmd="sleep 30"
  `#{cmd}`
  cmd="scp amcdmconfig02:/etc/puppet/regional/modules/amrimcdm/files/tpmgr-param.conf #{$cdm}:/opt/InCharge9/IP/smarts/regional/conf/discovery/tpmgr-param.conf"
  if system("#{cmd}")
    puts "success: #{cmd}"
  else
    puts "fail: #{cmd}"
  end
end

def copy_ssh
  cmd="ssh-copy-id root@#{$cdm}"
  if system("#{cmd}")
   puts "successful"
  end
end

def add_firewall_rules
  cmd="ssh root@#{$cdm} firewall-cmd --zone=public --add-port=5009/tcp"
  puts `#{cmd}`
  cmd="ssh root@#{$cdm} firewall-cmd --zone=public --add-port=5009/tcp --permanent"
  puts `#{cmd}`
end

def validate_puppet_conf_on_cdm
  puts "check you are using the right environment"
  cmd="ssh root@#{$cdm} cat /etc/puppet/puppet.conf"
  puts `#{cmd}`
end

def mainmenu
  puts "
 CDM Information
   0: enter CDM
   1: enter CDM IP address and other details
 Create DNS entries
   10: add internal (152.x) IP address to DNS server (1 entry)
   11: validate dns entries
 Create hiera data yaml file for #{$cdm}
   20: create /etc/puppet/environments/#{$puppet_env}/hieradata/node/#{$cdm_fqdn}.yaml file
   21: update /etc/puppet/environments/#{$puppet_env}/hieradata/node/#{$cdm_fqdn}.yaml file
   22: copy /etc/puppet/environments/#{$puppet_env}/hieradata/node/#{$cdm_fqdn}.yaml file
   23: validate /etc/puppet/environments/#{$puppet_env}/hieradata/node/#{$cdm_fqdn}.yaml file
 Edit /etc/puppet/manifests/site.pp
   30: edit /etc/puppet/manifests/site.pp
   31: validate /etc/puppet/manifests/site.pp file
   32: check /etc/puppet/puppet.conf on #{$cdm}
 Build VM in vCenter
   40: build VM in vCenter
   41: power on VM and run the script /opt/rim/scripts/assign-ip.sh from the VM console
 Puppet Run
   a: execute on #{$cdm} 3 times: time puppet agent --test 2>&1 | tee /var/log/puppet/cdm94.log.1
   b: enable amrimcdm,amncmdrivers::install,amapgcustom-snmp-collector::install,hqagent-cdm:install in /etc/puppet/environments/branches_RIM_9_4_1_0/hieradata/node/#{$cdm_fqdn}.yaml
   c: use tags amrimcdm,amncmdrivers,amapgcustom-snmp-collector,hqagent-cdm and execute on #{$cdm}: puppet agent --test --tags TAG 2>&1 | tee /var/log/puppet/cdm94.log.4
   42: print puppet log errors and warnings
   43: puppet agent run
 Post Puppet Run Steps
   49: copy ssh keys
   50: stop SMARTS,APG, and NCM on CDM
   51: set connected and connection on power for interfaces in vCenter
   52: start SMARTS,APG and NCM on CDM
   54: ncm unlock lockbox
   55: copy running.ncf from config server
   56: copy custom apm certifications
   57: add cdm to documentserver
   58: add firewall rules
   h: update system limits in SMARTS APM
   i: update IDM NOTIF
   j: Add annotation to cdm in vCenter: [autostart:yes][linux:backup][DR:replicated]
 Deploy in DEPSAM
   60: edit /etc/puppet/environments/latest/hieradata/node/amcalsamdep01.us.gsoa.local.yaml file
 Checks
   70: check smarts, apg and vcmaster
   99: Exit"
  print "select an option:"
  case gets.strip
  when "0"
    get_cdm
  when "1"
    get_cdm_details
  when "11"
    validate_dns
  when "20"
    create_cdm_hierayaml
  when "21"
    update_cdm_hierayaml
  when "22"
    copy_cdm_hierayaml
  when "23"
    validate_cdm_hierayaml
  when "30"
    edit_sitepp
  when "31"
    validate_sitepp
  when "32"
    validate_puppet_conf_on_cdm
  when "43"
     puppet_agent_run
  when "42"
    cmd="ssh root@#{$cdm} ls -ltr /var/log/puppet/"
    puts `#{cmd}`
    puts "enter log file:"
    myfile=gets.chomp
    cmd="ssh root@#{$cdm} grep Error: /var/log/puppet/#{myfile}"
    puts `#{cmd}`
    cmd="ssh root@#{$cdm} grep Warning: /var/log/puppet/#{myfile}"
    puts `#{cmd}`
  when "35"
    cmd="ssh root@#{$cdm} rm -rf /opt/rim/installers/*"
    #puts `#{cmd}`
  when "40"
    puts "deploy OVA template using \\\\152.110.244.222\\software\\RIM 9.4\\cdm-94-template.ova"
    puts "name is#{$cdm} inventory location is CDM 9.4"
    puts "for Host/Cluster use RIM-CLUSTER"
    puts "do not choose a resource pool"
    puts "choose VNX-LUN-40xx-CDM, one with max size available"
    puts "choose Thick-Provisioned Lazy-Zeroed"
    puts "choose CDM-240 as the network"
  when "41"
    puts "power on the VM"
    puts "run the script /opt/rim/scripts/assign-ip.sh"
  when "49"
    copy_ssh
  when "50"
    sm_service_status
    apg_status
    ncm_status
  when "52"
    sm_service_status
    apg_status
    ncm_status
  when "54"
    ncm_unlock_lockbox
  when "55"
    copy_running_ncf 
  when "56"
    copy_custom_apm_certifications
  when "57"
    add_cdm_to_documentserver
  when "58"
    add_firewall_rules
  when "60"
    puts "add entries to the /etc/puppet/environments/latest/hieradata/node/amcalsamdep01.us.gsoa.local.yaml file"
    puts " '"+"#{$CDM}"+"':"
    puts "      'OI': 'TRUE'"
    puts "      'APM': 'TRUE'"
    puts "ssh to amcalsamdep01 and execute: time puppet agent --test 2>&1 | tee /var/log/puppet/#{$cdm}.log.1 "
  when "70"
    smarts_apg_ncm_status
  when "99"
    $menu=1 
  end
end

while $menu==0
  mainmenu
end

