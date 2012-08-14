#!/usr/bin/env ruby

require 'lib/connect_mysql'

mysql = Connect_mysql.new('chuya', '0514')
patentproject = mysql.db('patentproject2012') #input db

q1 = patentproject.query("SELECT DISTINCT Patent_id FROM assignee ")
q1.each do |q|
  puts q
end

puts "total = #{q1.to_a.count}"