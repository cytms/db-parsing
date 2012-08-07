#!/usr/bin/env ruby

require 'mysql2'
db = Mysql2::Client.new(:host => '140.112.107.1', :username => 'chuya', :password=> '0514', :database => 'mypaper')
res = db.query("select Patent_id from `content_2009` limit 0,10")
res.each do |r|
  puts r['Patent_id']
end
