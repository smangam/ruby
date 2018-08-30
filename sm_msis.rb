#!/usr/bin/ruby
#


def mainmenu
 puts "select an option
   0: enter CDM
 DEVICE Information
   1: list devtypes
   2: list devices by devtype (you should enter the devtype)
   3: list devices by search string (enter % to list all devices)
 PARTTYPE and PART Information
   4: list parttypes for a device (required: device name)
   5: list parts for a device and parttype (required: device name and parttype)
 VARIABLE Information
   6: list variables for a device,parttype,and part (you should enter the device name)
 TIMESERIES Data
   7: list of raw/aggregate tables
   8: raw data for a variable id
   9: Exit"
  case gets.strip
  when "0"
    get_cdm
  end
end
