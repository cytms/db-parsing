#!/usr/bin/env ruby
# encoding: UTF-8

require 'nokogiri'
require 'open-uri'
require 'timeout'

require_relative  '../lib/connect_mysql'

@mysql = Connect_mysql.new('chuya', '0514')
@new_patent = @mysql.db('new_patent') #input/output db

def get_id(year, num)
  begin
    pid = @new_patent.query("SELECT `Patent_id` FROM content_#{year} ORDER BY `Index` ASC LIMIT #{num-1}, 1").to_a[0]['Patent_id']
  rescue => e
    puts "GET PATENT_ID, Index:#{num}  =>  Exception:#{e.to_s}"
    sleep(1)
    @mysql = Connect_mysql.new('chuya', '0514')
    @new_patent = @mysql.db('new_patent') #input/output db  
    retry
  end
  return pid
end

def get_html(pid)
  try_time = 1
  begin
    timeout(time_out) do
      page = Nokogiri::HTML(open("http://patft.uspto.gov/netacgi/nph-Parser?Sect1=PTO1&Sect2=HITOFF&d=PALL&p=1&u=%2Fnetahtml%2FPTO%2Fsrchnum.htm&r=1&f=G&l=50&s1=#{pid}.PN.&OS=PN/#{pid}&RS=PN/#{pid}", :read_timeout=>time_out-1)).to_s
      return page
    end
  rescue => e
    puts "Patent_id:#{pid}  =>  Exception:#{e.to_s}"
    if try_time > 5
      page = "not find"
    else
      try_time += 1
      retry
    end
  end
end

def get_page_title(page)
  html = Nokogiri::HTML(page)
  return html.title
end

def update_html(year, pid, html)
  mod_html = html.gsub(/\'/, "''").gsub(/\"/, '\"')
  begin
    @new_patent.query("UPDATE content_#{year} SET Html = '#{mod_html}' WHERE Patent_id = '#{pid}'")
  rescue => e
    puts "Patent_id:#{pid}  =>  Exception:#{e.to_s}"
    sleep(1)
    @mysql = Connect_mysql.new('chuya', '0514')
    @new_patent = @mysql.db('new_patent') #input/output db  
    retry
  end
end

def total_count(year)
  count = @new_patent.query("SELECT COUNT(*) FROM  `content_#{year}`").to_a[0]['COUNT(*)']
  return count.to_i
end

@year = ARGV[0]
count = total_count(@year)
(1..count).each do |i|
  patent_id = get_id(@year, i)
  puts "Now is going to get: year=>#{@year}, index=>#{i}, id=>#{patent_id}"
  page = get_html(patent_id)
  update_html(@year, patent_id, page)
  puts "Update: year=>#{@year}, index=>#{i}, id=>#{patent_id}"
end


(start_at..total_count).each do |i|
  if i % thread_num == 1
    period_num = i+thread_num-1
    if period_num > total_count
      period_num = total_count
    end
    
    #use thread
    threads = []
    data = []
    (i..period_num).each do |i|
      patent_id = get_id(@year, i)
      threads << Thread.new(@year, i, patent_id) do |year, index, id|        
        page = get_html(id)
        puts "index:#{index}  => patent_id:#{id} => page_title:#{get_page_title(page)}"  
        id_page = Hash['Patent_id'=>id, 'Html'=>page]
        data.push(id_page)
      end
    end
    threads.each do |thread|
      thread.join
    end
    data.each do |d|
      update_html(@year, d['Patent_id'], d['Html'])     
    end   
   
    puts "Year:#{@year}  =>  Index : #{i} to #{period_num} finish"
  end
end
puts "Process Duration: #{Time.now - start_time} seconds\n"

