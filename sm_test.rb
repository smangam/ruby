#!/usr/bin/ruby
#
File.open("/root/smangam/cdm_cal.txt").each do |x|
  if x =~ /apg/
    puts x
  end
end
