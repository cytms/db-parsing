#!/usr/bin/env ruby
# encoding: UTF-8

require 'lib/connect_mysql'

mysql = Connect_mysql.new('chuya', '0514')

#input db
patentproject = mysql.db('patentproject2012')

assignee = patentproject.query("SELECT Patent_id, Assignee FROM assignee WHERE Patent_id = 123")
if assignee.to_a.count == 0
  puts "there is no result"
end
