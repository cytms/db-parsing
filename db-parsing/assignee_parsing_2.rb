#!/usr/bin/env ruby
# encoding: UTF-8

require 'lib/connect_mysql'

mysql = Connect_mysql.new('chuya', '0514')

#input db
mypaper = mysql.db('mypaper')
#output db
patentproject = mysql.db('patentproject2012')
#output file
logfile = File.open('db-parsing/log/assignee_2009.log','w+')

patent_2009 = mypaper.query("SELECT Patent_id, Assignee FROM `content_2009` LIMIT 0,1000")

correct_assignee = []
incorrect_assignee = []
without_assignee = []

patent_2009.each do |p|
  patent_id = p['Patent_id']
  assignee = ""
  location = ""
  if p['Assignee'].nil?
    without_assignee.push(p['Patent_id'])
    s = sprintf("\npatent_id = #{patent_id}\n"+
    " "*4+"|result = without assignee\n")
    puts s
    logfile.write(s)
    #    patentproject.query("INSERT INTO assignee (Patent_id, Assignee, Location)
    #                         VALUES ('#{patent_id}', NULL, NULL) ")
  else
    assignee_str = p['Assignee'].strip().split(/(\([A-Z].*?,\s{2}[A-Z]{2}\)|\([A-Z].*?,\s{2}unknown\)|\([A-Z]{2}\))/)
    s = sprintf("\npatent_id = #{patent_id}\n"+
                " "*4+"|result = #{assignee_str.count}\n"+
                " "*8+"|origin = #{p['Assignee'].strip()}\n"+
                " "*12+"|str = #{assignee_str}")
    puts s
    logfile.write(s)
  end
end
