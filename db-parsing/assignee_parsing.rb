#!/usr/bin/env ruby
# encoding: UTF-8

require 'lib/connect_mysql'

mysql = Connect_mysql.new('chuya', '0514')

#input db
mypaper = mysql.db('mypaper')
#output db
patentproject = mysql.db('patentproject2012')

patent_2009 = mypaper.query("select Patent_id, Assignee from `content_2009` limit 0,10000 ")

p_more_assignee = []
max_assignee = 0
correct_assignee = []
without_assignee = []

patent_2009.each do |p|
  patent_id = p['Patent_id']
  assignee = nil
  location = nil
  if p['Assignee'].nil?
    without_assignee.push(p['Patent_id'])      
    puts "\npatent_id = #{patent_id}"
    puts "    |result = without assignee"
  else
    assignee_str = p['Assignee'].strip().split(/([A-Z]{2}\)|\([A-Z]{2}\)\s|\s*unknown\))/)
    #    location_index = assignee_str.index(/\(([a-zA-Z]|\s)*,\s[A-Z]*\)/)
    #    result = /(\s*[A-Z]{2}\)|\([A-Z]{2}\))/.match(assignee_str)
    if assignee_str.count.even? #and assignee_str.count/2 > 1
      correct_assignee.push(p['Patent_id'])                                                                 #
      puts "\npatent_id = #{patent_id}"
      puts "    |result = #{assignee_str.count}"
      puts "          |origin = #{p['Assignee'].strip()}"
      puts "              |str = #{assignee_str}"

      assignee_str.each do |str|
        if assignee_str.index(str).even?
          next_str = assignee_str[assignee_str.index(str)+1]
          if next_str.match(/\([A-Z]{2}\)/)
            assignee = str
            location = next_str.gsub(/(\(|\))/, '')
            puts "                  |assignee = #{assignee}"
            puts "                      |location = #{location}"

          else
            re_str = str.reverse
            re_str_split = re_str.split(/\(\s{1}/)
            if !re_str_split[1].nil?
              assignee = re_str_split[1].reverse
              location = (re_str_split[0].reverse + next_str).gsub(/(\(|\))/, '')
              puts "                  |assignee = #{assignee}"
              puts "                      |location = #{location}"
            end
          end
        end
      end

    else

    end

  end
  #  patentproject.query("INSERT INTO assignee (Patent_id, Assignee, Location)
  #                       VALUES ('#{patent_id}', '#{assignee}', '#{location}')    " )
end

puts "correct assignee number = #{correct_assignee.count}"
puts "without assignee number = #{without_assignee.count}"
puts "total patent number = #{patent_2009.count}"
