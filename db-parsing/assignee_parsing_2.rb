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

patent_2009 = mypaper.query("SELECT Patent_id, Assignee FROM `content_2009`")

country_code = []
patentproject.query("SELECT Code FROM `country_code`").to_a.map {|c| country_code.push(c['Code'])}
state_code = []
patentproject.query("SELECT Code FROM `state_code`").to_a.map {|s| state_code.push(s['Code'])}
cs_code = country_code + state_code
code_re = Regexp.new(cs_code.join("|"))

correct_assignee, incorrect_assignee, without_assignee = [], [], []

patent_2009.each do |p|
  patent_id = p['Patent_id']
  assignee = ""
  location = ""
  s = "\npatent_id = #{patent_id}\n"
  
  if p['Assignee'].nil?
#    without_assignee.push(p['Patent_id'])
#    s = s + " "*4+"|result = without assignee\n"
#    puts s
#    logfile.write(s)
    #    patentproject.query("INSERT INTO assignee (Patent_id, Assignee, Location)
    #                         VALUES ('#{patent_id}', NULL, NULL) ")
  else
    s = s + " "*4+"|orgin = #{p['Assignee'].strip()}\n"
    #assignee_str = p['Assignee'].strip().split(/(\(#{code_re}\)|\s{2}#{code_re}\)|\s{2}unknown\))/)
    #assignee_str = p['Assignee'].strip().gsub(/(\(#{code_re}\)|\s{2}#{code_re}\)|\s{2}unknown\))/, '')
    assignee_str = p['Assignee'].strip()
    if assignee_str.match(/(\(#{code_re}\)|#{code_re}\)|unknown\))/).nil?
      if assignee_str.match(/(\([A-Z]{2}\)|[A-Z]{2}\))/).nil?
        #part one incomplete assignee
        #        assignee = assignee_str.split(/\(/)
        #        s = sprintf("\npatent_id = #{patent_id}\n"+
        #                    " "*4+"|assignee = #{assignee}\n"+
        #                    " "*8+"|origin = #{p['Assignee'].strip()}\n")
        #        puts s
        #        logfile.write(s)
      else
        #part two incomplete assignee and strange location
#        assignee_array = assignee_str.split(/(\([A-Z]{2}\)|[A-Z]{2}\))/)
#        if assignee_array.count.odd? # 
#          assignee = assignee_str
#          location = nil
#          s = s + " "*8+"|assignee = #{assignee}\n"
#          puts s
#          logfile.write(s)         
#          
#        else
#          assignee_array.each do |a|
#            index = assignee_array.index(a)
#            if index.even?
#              next_a = assignee_array[index+1]
#              if next_a.match(/\([A-Z]{2}\)/)
#                assingee = a.strip
#                location = next_a
#              else
#                rev_a = a.reverse
#                location_index = rev_a.index(/\(/)
#                assingee = rev_a[location_index+1..-1].reverse.strip
#                location = rev_a[0..location_index].reverse + assignee_array[index+1]
#              end   
#              s = s + " "*8+"|assignee = #{assingee}\n" +
#                      " "*12+"|location = #{location}\n"         
#              puts s
#              logfile.write(s)     
#            end
#          end
#        end
      end
    else
      assignee_array = assignee_str.split(/(\(#{code_re}\)|#{code_re}\)|unknown\))/)
      if assignee_array.count.odd?
        s = s + " "*8+"|assignee_array = #{assignee_array}\n" +
                " "*12+"|count = #{assignee_array.count}"
        puts s
        logfile.write(s)     
      end

    end
  end
end
