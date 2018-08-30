#!/usr/bin/ruby
############################################
# APM menu driven program
# Author: sunil mangam
# date: june 15 2016
############################################

require '/root/smangam/didatacommon2'

################################
## variables
#################################
$menu=0
#$mysql="/opt/APG/Databases/MySQL/Default/bin/mysql"
#$sqlesc="\'\"\'\"\'"
#$cache0=[]
#$cache1hr=[]
#$cache1day=[]
#$cache1week=[]
#$variable_id=0
$apgdbfiles=["/root/smangam/amcalapgdb01","/root/smangam/amcalapgdb02","/root/smangam/amcalapgdb03","/root/smangam/amcalapgdb04","/root/smangam/amcalapgdb05","/root/smangam/amcalapgdb06","/root/smangam/amcalapgdb07"]
$apgdb={"amcalapgdb01"=>"apg", 
        "amcalapgdb02"=>"apg2",
        "amcalapgdb03"=>"apg3",
        "amcalapgdb04"=>"apg4",
        "amcalapgdb05"=>"apg5",
        "amcalapgdb06"=>"apg6",
        "amcalapgdb07"=>"apg7"
       }

###########################################
## functions
############################################

def get_dbhost
# mysql -s option is for silent output. boxes around the output are supressed
# mysql -N use this option to skip column names
  #sql="select distinct custtag from data_property_flat where vstatus='active' ;"
  sql='"'+"select distinct custtag from data_property_flat where vstatus=\'\"\'\"\'active\'\"\'\"\';"+'"'

  f=File.new($apgdbfiles[0],"w")
  cmd="ssh root@amcalapgdb01 "+"'"+$mysql +" -Ns -h amcalapgdb01 -u apg -e " + sql +" apg"+"'"
  cdmapg=`#{cmd}`.chomp
  f.puts cdmapg
  f.close

  f=File.new($apgdbfiles[1],"w")
  cmd="ssh root@amcalapgdb02 "+"'"+$mysql +" -Ns -h amcalapgdb02 -u apg -e " + sql +" apg2"+"'"
  cdmapg2=`#{cmd}`.chomp
  f.puts cdmapg2
  f.close

  f=File.new($apgdbfiles[2],"w")
  cmd="ssh root@amcalapgdb03 "+"'"+$mysql +" -Ns -h amcalapgdb03 -u apg -e " + sql +" apg3"+"'"
  cdmapg3=`#{cmd}`.chomp
  f.puts cdmapg3
  f.close

  f=File.new($apgdbfiles[3],"w")
  cmd="ssh root@amcalapgdb04 "+"'"+$mysql +" -Ns -h amcalapgdb04 -u apg -e " + sql +" apg4"+"'"
  cdmapg4=`#{cmd}`.chomp
  f.puts cdmapg4
  f.close

  f=File.new($apgdbfiles[4],"w")
  cmd="ssh root@amcalapgdb05 "+"'"+$mysql +" -Ns -h amcalapgdb05 -u apg -e " + sql +" apg5"+"'"
  cdmapg5=`#{cmd}`.chomp
  f.puts cdmapg5
  f.close

  f=File.new($apgdbfiles[5],"w")
  cmd="ssh root@amcalapgdb06 "+"'"+$mysql +" -Ns -h amcalapgdb06 -u apg -e " + sql +" apg6"+"'"
  cdmapg6=`#{cmd}`.chomp
  f.puts cdmapg6
  f.close

  f=File.new($apgdbfiles[6],"w")
  cmd="ssh root@amcalapgdb07 "+"'"+$mysql +" -Ns -h amcalapgdb07 -u apg -e " + sql +" apg7"+"'"
  cdmapg7=`#{cmd}`.chomp
  f.puts cdmapg7
  f.close
end

def find_dbhost(cdm)
  $apgdbfiles.each { |x|
    if system("grep ^#{cdm}$ #{x}")
      $db_host= x.split('/')[-1]
      $apgdb = $apgdb[$db_host]
    end
  }
end

def get_epoch(mydate)
 #this function takes a date in the format "2016-08-24 09:00" and returns the epoch time
 #date -d "2016-08-24 09:00" +%s
 cmd="date -d #{mydate} +%s"
 `#{cmd}`
end
 
def get_part_for_a_device_and_parttype
  if $apg_device != nil
    print "get part for device #{$apg_device} (yes/no)?"
    output=gets.chomp
    if output=="no" then
      print "Please enter the device:"
      $apg_device = gets.chomp
    end
  else
      print "Please enter the device:"
      $apg_device = gets.chomp
  end
  print "Please enter the parttype:"
  $parttype = gets.chomp
  sql='"' + "select distinct part from data_property_flat where custtag=#{$sqlesc}#{$CDM}#{$sqlesc} and device=#{$sqlesc}#{$apg_device}#{$sqlesc} and parttype=#{$sqlesc}#{$parttype}#{$sqlesc} order by part;" +'"'
  cmd="ssh root@#{$apg_cdm_dbhost} "+"'"+" #{$mysql} --column-names -h #{$apg_cdm_dbhost} -u apg -e " +sql+" #{$apg_cdm_db} -t"+"'"
  output = `#{cmd}`
  puts output
end

def get_id_for_a_device_and_parttype
  if $apg_device != nil && $parttype != nil
    print "get metrics (variable id's) for device #{$apg_device} and parttype #{$parttype} (yes/no)?"
    output=gets.chomp
    if output=="no" then
      print "Please enter the device:"
      $apg_device = gets.chomp
      print "Please enter the parttype:"
      $parttype = gets.chomp
    end
  else
    print "Please enter the device:"
    $apg_device = gets.chomp
    print "Please enter the parttype:"
    $parttype = gets.chomp
  end
  #sql='"' + "select  distinct left(device,10),parttype,left(part,35),left(name,20),id,source from data_property_flat where custtag=#{$sqlesc}#{$CDM}#{$sqlesc} and device=#{$sqlesc}#{$apg_device}#{$sqlesc} and ( parttype=#{$sqlesc}#{$parttype}#{$sqlesc} or parttype is null) order by parttype,part ;" +'"'
  sql='"' + "select  distinct parttype,left(part,65),left(name,40),id,source from data_property_flat where custtag=#{$sqlesc}#{$CDM}#{$sqlesc} and device=#{$sqlesc}#{$apg_device}#{$sqlesc} and ( parttype=#{$sqlesc}#{$parttype}#{$sqlesc} or parttype is null) order by parttype,part ;" +'"'
  cmd="ssh root@#{$apg_cdm_dbhost} "+"'"+" #{$mysql} --column-names -h #{$apg_cdm_dbhost} -u apg -e " +sql+" #{$apg_cdm_db} -t"+"'"
  output = `#{cmd}`
  puts output
end

def get_id_for_a_device_and_parttype_b
  if $apg_device != nil && $parttype != nil
    print "get metrics (variable id's) for device #{$apg_device} and parttype #{$parttype} (yes/no)?"
    output=gets.chomp
    if output=="no" then
      print "Please enter the device:"
      $apg_device = gets.chomp
      print "Please enter the parttype:"
      $parttype = gets.chomp
    end
  else
    print "Please enter the device:"
    $apg_device = gets.chomp
    print "Please enter the parttype:"
    $parttype = gets.chomp
  end
  print "Please enter the part:"
  $part = gets.chomp
  #sql='"' + "select  distinct left(device,10),parttype,left(part,35),left(name,20),id,source from data_property_flat where custtag=#{$sqlesc}#{$CDM}#{$sqlesc} and device=#{$sqlesc}#{$apg_device}#{$sqlesc} and ( parttype=#{$sqlesc}#{$parttype}#{$sqlesc} or parttype is null) order by parttype,part ;" +'"'
  sql='"' + "select  distinct left(part,65),left(name,20),id,ifalias,source from data_property_flat where custtag=#{$sqlesc}#{$CDM}#{$sqlesc} and device=#{$sqlesc}#{$apg_device}#{$sqlesc} and ( parttype=#{$sqlesc}#{$parttype}#{$sqlesc} or parttype is null) and part=#{$sqlesc}#{$part}#{$sqlesc} order by parttype,part ;" +'"'
  cmd="ssh root@#{$apg_cdm_dbhost} "+"'"+" #{$mysql} --column-names -h #{$apg_cdm_dbhost} -u apg -e " +sql+" #{$apg_cdm_db} -t"+"'"
  output = `#{cmd}`
  puts output
end

def get_id_for_a_device_and_name
  if $apg_device != nil
    print "get metrics (variable id's) for device #{$apg_device} (yes/no)?"
    output=gets.chomp
    if output=="no" then
      print "Please enter the device:"
      $apg_device = gets.chomp
    end
  else
    print "Please enter the device:"
    $apg_device = gets.chomp
  end
  print "Please enter the metric search string (use % to list all metrics):"
  $name = gets.chomp

  sql='"' + "select  distinct left(part,65),left(name,20),id,source from data_property_flat where custtag=#{$sqlesc}#{$CDM}#{$sqlesc} and device=#{$sqlesc}#{$apg_device}#{$sqlesc} and name like #{$sqlesc}%#{$name}%#{$sqlesc} order by parttype,part ;" +'"'
  cmd="ssh root@#{$apg_cdm_dbhost} "+"'"+" #{$mysql} --column-names -h #{$apg_cdm_dbhost} -u apg -e " +sql+" #{$apg_cdm_db} -t"+"'"
  output = `#{cmd}`
  puts output
end

def get_property
  if $apg_device != nil && $parttype != nil
    print "get metrics (variable id's) for device #{$apg_device} and parttype #{$parttype} (yes/no)?"
    output=gets.chomp
    if output=="no" then
      print "Please enter the device:"
      $apg_device = gets.chomp
      print "Please enter the parttype:"
      $parttype = gets.chomp
    end
  else
    print "Please enter the device:"
    $apg_device = gets.chomp
    print "Please enter the parttype:"
    $parttype = gets.chomp
  end
  puts "list of properties"
  sql='"' + "select column_name from information_schema.columns where table_name=#{$sqlesc}data_property_flat#{$sqlesc} ;" +'"'
  cmd="ssh root@#{$apg_cdm_dbhost} "+"'"+" #{$mysql} --column-names -h #{$apg_cdm_dbhost} -u apg -e " +sql+" #{$apg_cdm_db} -t"+"'"
  output = `#{cmd}`
  puts output

  puts "enter list of properties that you want to query(comma separated list, example: source,maxspeed):"
  myproperty=gets.chomp
  sql='"' + "select  distinct custtag,device,parttype,part,#{myproperty} from data_property_flat where custtag=#{$sqlesc}#{$CDM}#{$sqlesc} and device=#{$sqlesc}#{$apg_device}#{$sqlesc} and ( parttype=#{$sqlesc}#{$parttype}#{$sqlesc} or parttype is null) order by parttype,part ;" +'"'
  #sql='"' + "select  distinct left(part,65),left(name,20),ifalias,source,maxspeed from data_property_flat where custtag=#{$sqlesc}#{$CDM}#{$sqlesc} and device=#{$sqlesc}#{$apg_device}#{$sqlesc} and ( parttype=#{$sqlesc}#{$parttype}#{$sqlesc} or parttype is null) order by parttype,part ;" +'"'
  cmd="ssh root@#{$apg_cdm_dbhost} "+"'"+" #{$mysql} --column-names -h #{$apg_cdm_dbhost} -u apg -e " +sql+" #{$apg_cdm_db} -t"+"'"
  output = `#{cmd}`
  puts output
end

def read_file
 print "enter file to read:"
 myfile=gets.chomp
 File.open(myfile).each {|line| puts line}
end

def delete_file
 print "enter file to delete:"
 myfile=gets.chomp
 cmd="rm -rf #{myfile}"
 puts `#{cmd}`
end

def mainmenu
 if $cdm != nil; puts "CDM is "+$cdm end
 if $apg_device != nil; puts "Device is "+$apg_device end
 puts "select an option
   0: enter CDM
   0a: select APG portal(default is amcdlapgprtl01):
 DEVICE Information
   1: list devtypes
   2: list devices by devtype (you should enter the devtype)
   3: list devices by search string (enter % to list all devices)
   4: list properties
 PARTTYPE and PART Information
   20: list parttypes for a device (required: device name)
   21: list parts for a device and parttype (required: device name and parttype)
 METRIC Information
   30: list metrics for a device,parttype (you should enter the device name)
   31: list metrics for a device,parttype,and part (enter the part name)
   32: list metrics for a device using search string
 TIMESERIES Data
   40: list of raw/aggregate tables
   41: raw data for a metric
   42: read a file
   43: remove the file
 APG and ITSM Performance Reports
   50: Service Properties and Contract needed for CI Performance Reports
   99: Exit"
  case gets.strip
  when "0"
    Didatacommon.get_cdm
    Didatacommon.apg_build_cachetables
  when "0a"
    Didatacommon.apg_get_prtlhost
  when "1"
    Didatacommon.apg_get_devtypes
  when "2"
    Didatacommon.apg_get_devices_by_devtype
  when "3"
    Didatacommon.apg_get_devices_by_string
  when "4"
    get_property
  when "20"
    Didatacommon.apg_get_parttypes_for_a_device
  when "21"
    get_part_for_a_device_and_parttype
  when "30"
    get_id_for_a_device_and_parttype
  when "31"
    get_id_for_a_device_and_parttype_b
  when "32"
    get_id_for_a_device_and_name
  when "40"
    Didatacommon.apg_list_cache_tables
  when "41"
    Didatacommon.apg_raw_data
  when "42"
    read_file
  when "43"
    delete_file
  when "50"
    Didatacommon.apg_itsm_perf_report_contracts
  when "99"
    $menu=1
    puts "exiting..."
  end
end

while $menu==0
  mainmenu
end
