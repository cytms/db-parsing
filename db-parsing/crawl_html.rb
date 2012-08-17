#!/usr/bin/env ruby
# encoding: UTF-8

require 'nokogiri'
require 'open-uri'

require_relative  '../lib/connect_mysql'

@mysql = Connect_mysql.new('chuya', '0514')
@new_patent = @mysql.db('new_patent') #input/output db

def get_id(year, num)
  pid = @new_patent.query("SELECT `Patent_id` FROM content_#{year} ORDER BY `Index` ASC LIMIT #{num-1}, 1").to_a[0]['Patent_id']
  return pid
end

def get_html(pid)
  begin
    page = Nokogiri::HTML(open("http://patft.uspto.gov/netacgi/nph-Parser?Sect1=PTO1&Sect2=HITOFF&d=PALL&p=1&u=%2Fnetahtml%2FPTO%2Fsrchnum.htm&r=1&f=G&l=50&s1=#{pid}.PN.&OS=PN/#{pid}&RS=PN/#{pid}")).to_s
  rescue => e
    puts "Patent_id:#{pid}  =>  Exception:#{e.to_s}"
    sleep(1)
    retry
  end
  return page
end

def update_html(year, pid, html)
  mod_html = html.gsub(/\'/, "''").gsub(/\"/, '\"')
  @new_patent.query("UPDATE content_#{year} SET Html = '#{mod_html}' WHERE Patent_id = '#{pid}'")
end

@year = 2011
patent_id = get_id(@year, 1)
page = get_html(patent_id)
update_html(@year, patent_id, page)


