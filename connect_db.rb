#!/usr/bin/env ruby

require 'mysql2'
db = Mysql2::Client.new(:host => '140.112.107.1', :username => 'chuya', :password=> '0514', :database => 'patentproject2012', :encoding => 'utf8')

res = db.query("select * from `abbreviations` limit 0,2")
res.each do |r|
  puts r
end
