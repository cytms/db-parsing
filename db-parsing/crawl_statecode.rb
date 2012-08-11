#!/usr/bin/env ruby
# encoding: UTF-8

require 'nokogiri'
require 'open-uri'
require 'lib/connect_mysql'

mysql = Connect_mysql.new('chuya', '0514')
##output db
patentdb = mysql.db('patentproject2012')

page = Nokogiri::HTML(open('http://www.uspto.gov/patft/help/helpst.htm'))
tr = page.css('tbody tr').drop(1)
tr.each do |t|
  i = tr.index(t)
  td = t.css('td')
  if i == 0
    (1..2).each do |j|
      state = td[2*j-1].content.rstrip
      code = td[2*j].content
      puts "state: #{state}   code:#{code}"
      patentdb.query("INSERT INTO state_code (Code, State)
                      VALUES ('#{code}', '#{state}')         ")
    end
  else
    (0..1).each do |j|
      state = td[2*j].content.rstrip
      code = td[2*j+1].content
      if code.match(/\(NB\)/)   # The state abbreviation for Nebraska used in patents prior to July 4, 1978 was NB rather than NE.
        code = code.gsub(/\(NB\)/, '').rstrip
        puts "state: #{state}   code:#{code}"
        patentdb.query("INSERT INTO state_code (Code, State)
                        VALUES ('#{code}', '#{state}')         ")
        puts "state: #{state}   code:NB"
        patentdb.query("INSERT INTO state_code (Code, State)
                        VALUES ('NB', '#{state}')              ")
      else
        puts "state: #{state}   code:#{code}"
        patentdb.query("INSERT INTO state_code (Code, State)
                        VALUES ('#{code}', '#{state}')         ")
      end      
    end
  end
end
