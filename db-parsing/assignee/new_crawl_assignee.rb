#!/usr/bin/env ruby
# encoding: UTF-8

require 'nokogiri'
require 'open-uri'
require 'lib/connect_mysql'

def get_patent_id(mysql, query_year, query_limit)
  mypaper = mysql.db('mypaper') #input db
  patent_id = mypaper.query("SELECT Patent_id FROM content_#{query_year} ORDER BY Patent_id ASC #{query_limit}")
  return patent_id
end

def get_assignee(patent_id)
  begin
    page = Nokogiri::HTML(open("http://patft.uspto.gov/netacgi/nph-Parser?Sect1=PTO1&Sect2=HITOFF&d=PALL&p=1&u=%2Fnetahtml%2FPTO%2Fsrchnum.htm&r=1&f=G&l=50&s1=#{patent_id}.PN.&OS=PN/#{patent_id}&RS=PN/#{patent_id}"))
  rescue => e
    puts "Patent_id:#{patent_id}  =>  Exception:#{e.to_s}"
    sleep(1)
    retry
  end
  page_title = page.css('title').to_s
  return_data = {}
  return_data['Patent_id'] = patent_id
  return_data['data'] = []

  if page_title.match(/#{patent_id}/).nil? #title != patent id
    return_data['result'] = -1
  else #title == patent id
    assignee_tr = page.xpath("//table")[3].css('tr')[1]
    if assignee_tr.to_s.match(/Assignee:/).nil? #without assignee
      return_data['result'] = 0
    else
      return_data['result'] = 1
      assignee, location = [], []
      assignee_td = assignee_tr.css('td')[1]
      assignee_with_location = assignee_td.to_s.split("<br>")

      (0..assignee_with_location.count-2).each do |i|
        a_l_html = Nokogiri::HTML(assignee_with_location[i])
        assignee[i] = a_l_html.css('b')[0].text
        location[i] = a_l_html.text.strip[assignee[i].length..-1].gsub(/\n/,'')
        data = Hash['Assignee'=>assignee[i], 'Location'=>location[i]]
        return_data['data'].push(data)
      end
    end
  end
  return return_data
end

def crawl(query_year, query_start, query_num)
  year, start, num = query_year, query_start, query_num
  limit = "LIMIT #{start}, #{num}"
  mysql = Connect_mysql.new('chuya', '0514')
  patentproject = mysql.db('patentproject2012') #output db

  logfile_assignee = File.open("db-parsing/assignee/log/#{year}/crawl_assignee_#{year}_#{limit}.log",'w+') #output log file
  logfile_assignee.write("Crawling Assignee from USPTO -- #{year} -- #{limit}\n")

  patent = get_patent_id(mysql, year, limit)

  auto_index = start.to_i+1
  patent.each do |p|
    assignee_data = get_assignee(p['Patent_id'])
    pid = assignee_data['Patent_id']
    if assignee_data['result'] == 1
      assignee_data['data'].each do |d|
        modify_assignee = d['Assignee'].gsub(/'/, "''")
        modify_location = d['Location'].gsub(/'/, "''")
        begin
          patentproject.query("INSERT INTO test_assignee_2007 (Patent_id, Assignee, Location)
                               VALUES ('#{pid}', '#{modify_assignee}', '#{modify_location}') ")
          q = patentproject.query("SELECT Patent_id FROM test_assignee_2007
                                   WHERE Patent_id = '#{pid}' AND Assignee = '#{modify_assignee}'AND Location = '#{modify_location}' ")
          if q.to_a.count == 0
            raise "Insert Failure"
          end
        rescue => e
          s = "Index:#{auto_index}  =>  Patent_id:#{p['Patent_id']}  =>  Exception:#{e.to_s}\n"
          puts s
          logfile_assignee.write(s)
          if e.to_s == "Insert Failure"
            retry
          end
        end
        s = "Index:#{auto_index}  =>  Patent_id:#{pid}  =>  Assignee:#{d['Assignee']}  =>  Location:#{d['Location']}\n"
        puts s
        logfile_assignee.write(s)
      end

    elsif assignee_data['result'] == 0
      s = "Index:#{auto_index}  =>  Patent_id:#{pid}  =>  without assignee\n"
      puts s
      logfile_assignee.write(s)

    else
      s = "Index:#{auto_index}  =>  Patent_id:#{pid}  =>  page title does not equal to patent id\n"
      puts s
      logfile_without.write(s)
    end
    auto_index += 1
  end
end


#THREAD_LENGTH = 10
thread_arr = []
puts "process start\n"
start_time = Time.now
  
(0..3).each do |i|
  thread_arr[i] = Thread.new('2008', i*1250, 1250) do |year, start, count|
    crawl(year, start, count)
  end
end

thread_arr.each do |th|
  th.join
end
puts "Process Duration: #{Time.now - start_time} seconds\n"
puts "threads end"

