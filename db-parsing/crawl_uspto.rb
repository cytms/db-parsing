#!/usr/bin/env ruby
# encoding: UTF-8

require 'nokogiri'
require 'open-uri'

require_relative  '../lib/connect_mysql'

@root_url = "http://patft.uspto.gov"
@mysql = Connect_mysql.new('chuya', '0514')
@new_patent = @mysql.db('new_patent') #input db

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

def get_jump_page(year, num)
  begin
    start_url = @root_url+"/netacgi/nph-Parser?Sect1=PTO2&Sect2=HITOFF&u=%2Fnetahtml%2FPTO%2Fsearch-adv.htm&r=0&f=S&l=50&d=PTXT&RS=ISD%2F#{year}0101-%3E#{year}1231&Query=isd%2F1%2F1%2F#{year}-%3E12%2F31%2F#{year}&TD=176082&Srch1=%40PD%3E%3D#{year}0101%3C%3D#{year}1231&StartAt=Jump+To&StartAt=Jump+To&StartNum=#{num}"
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
    patent_id = td[1].text.gsub(/,/,"")
    title = td[3].text.gsub(/'/, "''").gsub(/\n/, '').gsub(/\s{4}/, '').chomp
    url = @root_url+td[1].css('a')[0]['href']
    puts "index:#{index}\npatent_id:#{patent_id}\ntitle:#{title}\nurl:#{url}\n"

    @new_patent.query("INSERT INTO content_#{@year} (`Index`, `Patent_id`, `Title`)
                    VALUES ('#{index}', '#{patent_id}', '#{title}') ")
    puts "--------------------------------------------------"
  end
end

def get_next_url(page)
  next_page = page.css('table')[2].css('td a')
  if next_page.to_a.count == 4
    next_page_url = @root_url+next_page[0]['href'].gsub(/>/, "%3E")
    if next_page_url.match(/Page=Prev/)
      next_page_url = nil
    end
  elsif next_page.to_a.count == 5
    next_page_url = @root_url+next_page[1]['href'].gsub(/>/, "%3E")
  end
  return next_page_url
end

puts "process start\n"
start_time = Time.now

if ARGV.count == 1
  @year = ARGV[0]
  page = get_start_page(@year)
  next_url = get_next_url(page)
elsif ARGV.count == 2
  @year = ARGV[0]
  num = ARGV[1]
  page = get_jump_page(@year, num)
  next_url = get_next_url(page)
end

while !next_url.nil?
  crawl_patent(page)
  next_url = get_next_url(page)
  puts "next_url:#{next_url}"
  if !next_url.nil?
    page = get_next_page(next_url)
  else
    puts "END PAGE"
  end
end

puts "Process Duration: #{Time.now - start_time} seconds\n"
puts "Process end"
