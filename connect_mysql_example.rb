#!/usr/bin/env ruby
require 'connect_mysql'

test = Connect_mysql.new('chuya', '0514')
#puts "host : " + test.host
#puts "username : " + test.username
#puts "password : " + test.password

mypaper = test.db('mypaper')
res = mypaper.query("select Patent_id from `content_2009` limit 0,10")
res.each do |r|
  puts r['Patent_id']
end