#!/usr/bin/ruby

print "enter target server:"
target_server=gets.chomp
cmd="ssh-copy-id root@#{target_server}"
if system("#{cmd}")
  puts "successful"
end
