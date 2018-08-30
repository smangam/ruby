#!/usr/bin/ruby
#########################################
# author: sunil mangam
# version: 1.3
#
#########################################

require '/root/smangam/didatacommon'

$menu=0

def mainmenu
 puts "select an option
   0: enter CDM or ip address
 Raw Device
   10: list raw devices (raw device is a full device, not a partition)
   11: list partitons on a given raw device
   12: create a new partition (of type lvm) on the raw device - helpfile
 LVM
   20: create a PV on a new partition -helpfile
   21: list VGs on #{$cdm}
   22: list PVs
   23: list LVs
   24: add a PV to VG -helpfile
   25: extend an LV -helpfile
 EXIT Program
   99: Exit"

  case gets.strip
  when "0"
    print "enter hostname or ip address:"
    $cdm=gets.chomp
  when "10"
    Didatacommon.get_raw_device
  when "11"
    Didatacommon.get_device_partitions
  when "12"
    Didatacommon.create_lvm_partition_help
  when "20"
    Didatacommon.create_pv_help
  when "21"
    Didatacommon.get_vgs
  when "22"
    Didatacommon.get_pvs
  when "23"
    Didatacommon.get_lvs
  when "24"
    Didatacommon.add_pv_to_vg_help
  when "25"
    Didatacommon.extend_lv_help
  when "99"
    exit
  end
end

while $menu==0
  mainmenu
end

