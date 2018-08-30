#!/usr/bin/ruby

require '/root/smangam/didatacommon'
$menu=0  

def myMenu
 puts "Choose an option:
 APG CDM SNMP Collector Instances
   10: Enter CDM
   11: List SNMP Collector instances for #{$cdm}
 Agent (Device) Details
   20: list all agents
   21: list all explicit groups (a group contains a list of agents)
   22: list of groups with agents assigned
 Polling Groups (PG)
   30: list of agent groups used in PG
 Exit
   99: Exit"
 case gets.strip
 when "10"
   Didatacommon.get_cdm
 when "11"
   Didatacommon.apg_cdm_snmp_collector_instances
 when "20"
   Didatacommon.apg_cdm_snmp_agent_list
 when "21"
   Didatacommon.apg_cdm_snmp_agent_group_list
 when "22"
   Didatacommon.apg_cdm_snmp_agent_groups_with_agents
 when "30"
   Didatacommon.apg_cdm_snmp_pg_list
 when "99"
   $menu=1
   print "exiting..."
 end
end

############################
# main program
############################
while $menu==0
  myMenu
end

