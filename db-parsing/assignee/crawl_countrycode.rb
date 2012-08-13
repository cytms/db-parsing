#!/usr/bin/env ruby
# encoding: UTF-8

require 'nokogiri'
require 'open-uri'
require 'lib/connect_mysql'

mysql = Connect_mysql.new('chuya', '0514')
#output db
patentdb = mysql.db('patentproject2012')

page = Nokogiri::HTML(open('http://www.uspto.gov/patft/help/helpctry.htm'))
first_column = page.css('tbody tr td').to_a[0]
country_list = first_column.to_s.split("<br>").drop(2)
country_list.each do |c|
  code = c.strip[0..1]
  country = c.strip[2..-1].strip.gsub(/\r\n/, ' ').gsub(/<\/td>/, '')
  puts "code : #{code}   country : #{country}"
  patentdb.query("INSERT INTO country_code (Code, Country)
                  VALUES ('#{code}', '#{country}')         ")
end

