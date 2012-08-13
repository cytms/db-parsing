#!/usr/bin/env ruby
# encoding: UTF-8

require 'lib/connect_mysql'

test = Connect_mysql.new('chuya', '0514')
#puts "host : " + test.host
#puts "username : " + test.username
#puts "password : " + test.password

mypaper = test.db('mypaper')

#patentproject = test.db('patentproject2012')
res1 = mypaper.query("select Patent_id, Assignee from `content_2009` where `Assignee` regexp ' Inc.' limit 0,30")
res1.each do |r|
  puts r
end

total = mypaper.query("select count(Patent_id) from `content_2009`")
puts total.to_a

