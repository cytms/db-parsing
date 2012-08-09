#!/usr/bin/env ruby
# encoding: UTF-8

require 'lib/connect_mysql'

mysql = Connect_mysql.new('chuya', '0514')

#input db
patentproject = mysql.db('patentproject2012')

assignee = patentproject.query("select Patent_id, Assignee from `Assignee` limit 0,10 ")
assignee.each do |a|
  puts a['Assignee']
end