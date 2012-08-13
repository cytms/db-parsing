#!/usr/bin/env ruby
# encoding: UTF-8

require 'nokogiri'
require 'open-uri'
require 'watir-webdriver'
require 'lib/connect_mysql'

mysql = Connect_mysql.new('chuya', '0514')
mypaper = mysql.db('mypaper') #input db
patentproject = mysql.db('patentproject2012') #output db

logfile_assignee = File.open('db-parsing/log/crawl_assignee_2009.log','w+') #output file
logfile_assignee.write("Crawling Assignee from USPTO -- 2009\n")

logfile_without = File.open('db-parsing/log/crawl_without_assignee_2009.log','w+') #output file
logfile_without.write("Without Assignee or Error from USPTO -- 2009\n")

patent_2009 = mypaper.query("SELECT Patent_id FROM `content_2009` LIMIT 0,100") #fetch patent id
browser = Watir::Browser.new :ff #open firefox
browser.goto 'http://patft.uspto.gov/netahtml/PTO/srchnum.htm'

with_assignee, without_assignee, page_error = [], [], []

patent_2009.each do |p|
  browser.text_field(:name => 'TERM1').set p['Patent_id']
  browser.button(:value => 'Search').click
  Watir::Wait.until { browser.title.include? 'United States Patent:' }

  page_title = browser.title
  #check patent id and web page title
  if !page_title.match(/#{p['Patent_id']}/).nil?  #title == patent id
    if browser.html.match(/Assignee:/).nil? #without assignee
      without_assignee.push(p['Patent_id'])
      s = "Patent_id:#{p['Patent_id']}  =>  without assignee\n"
      puts s
      logfile_without.write(s)
    else #have assignee
      with_assignee.push(p['Patent_id'])
      assignee = []
      location = []
      assignee_with_location = browser.table(:index => 3).tbody.tr(:index => 1).td(:index => 1).text.split("\n")
      assignee_td = Nokogiri::HTML(browser.table(:index => 3).tbody.tr(:index => 1).html).css('td')[1]
      assignee_array = assignee_td.to_s.split("<br>")
      (0..assignee_array-2).each do |i|
        assignee.push(Nokogiri::HTML(assignee_array[i]).css('b')[0].text)
      end
      
      if assignee.count == assignee_with_location.count  #double check   
        assignee_with_location.each do |al|  #location = assignee_with_location - assignee
          index = assignee_with_location.index(al)
          location.push(al.gsub(/#{assignee[index]}/, '').strip)
        end
        
        (0..assignee.count-1).each do |i|
          s = "Patent_id:#{p['Patent_id']}  =>  Assignee:#{assignee[i]}  =>  Location:#{location[i]}\n"
          puts s
          logfile_assignee.write(s)
        end                
        
      else  #error occur
        s = "Patent_id:#{p['Patent_id']}  =>  a_l.count = #{assignee_with_location.count} != assignee.count = #{assignee.count}\n"
        puts s
        logfile_without.write(s)
      end
    end
    
  else  #when title != patent id
    page_error.push(p['Patent_id'])
    s = "Patent_id:#{p['Patent_id']}  =>  page title [ #{page_title} ] does not equal to patent id\n"
    puts s
    logfile_without.write(s)
  end

  browser.goto 'http://patft.uspto.gov/netahtml/PTO/srchnum.htm'
end

s = "with_assignee = #{with_assignee.count}\n"+
"without_assignee = #{without_assignee.count}\n"+
"page_error = #{page_error}\n"+
"total = #{with_assignee.count+without_assignee.count+page_error.count}\n"
puts s
logfile_assignee.write(s)

browser.close
logfile_assignee.close
logfile_without.close

