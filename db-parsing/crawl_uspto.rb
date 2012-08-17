#!/usr/bin/env ruby
# encoding: UTF-8

require 'nokogiri'
require 'open-uri'
require 'lib/connect_mysql'

@root_url = "http://patft.uspto.gov"
@mysql = Connect_mysql.new('chuya', '0514')
@mypaper = mysql.db('mypaper') #input db


def get_start_page(year)
  begin
    start_url = @root_url+"/netacgi/nph-Parser?Sect1=PTO2&Sect2=HITOFF&u=%2Fnetahtml%2FPTO%2Fsearch-adv.htm&r=0&p=1&f=S&l=50&Query=isd%2F1%2F1%2F#{year}-%3E12%2F31%2F#{year}&d=PTXT"
    start_page = Nokogiri::HTML(open(start_url))
  rescue => e
    puts "Start_page  =>  Exception:#{e.to_s}"
    sleep(1)
    retry
  end
  return start_page
end

def get_next_page(url)
  begin
    next_page = Nokogiri::HTML(open(url))
  rescue => e
    puts "Next_page  =>  Exception:#{e.to_s}"
    sleep(1)
    retry
  end
  return next_page
end

def crawl_patent(page)
  table = page.css('table')[1]
  tr = table.css('tr')
  (1..tr.to_a.count-1).each do |i|
    td = tr[i].css('td')
    index = td[0].text
    patent_id = td[1].text
    title = td[3].text.chomp.gsub(/\'/, "''")
    url = @root_url+td[3].css('a')[0]['href']
    @mypaper.query("INSERT INTO content_2010 (Index, Patent_id, Title, Url)
                    VALUES ('#{index}', '#{patent_id}', '#{title}', '#{url}') ")
    
    puts "index:#{index}\npatent_id:#{patent_id}\ntitle:#{title}\nurl:#{url}\n"
    puts "--------------------------------------------------"
  end
end

def get_next_url(page)
  next_page = page.css('table')[2].css('td a')
  if next_page.to_a.count == 4
    next_page_url = @root_url+page.css('table')[2].css('td a')[0]['href']
    if next_page_url.match(/Page=Prev/)
      next_page_url = nil
    end
  elsif next_page.to_a.count == 5
    next_page_url = @root_url+page.css('table')[2].css('td a')[1]['href']
  end
  return next_page_url
end


year = "2010"
page = get_start_page(year)
next_url = get_next_url(page)
while !next_url.nil?
  crawl_patent(page)
  next_url = get_next_url(page)
  page = get_next_page(next_url)
end
