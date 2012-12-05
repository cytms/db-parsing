#!/usr/bin/env ruby
# encoding: UTF-8
require 'timeout'
require_relative  '../lib/connect_mysql'

@mysql = Connect_mysql.new('chuya', '0514')
@new_patent_db = @mysql.db('new_patent') #new_patent db
@mypaper_db = @mysql.db('mypaper') #mypaper db


def total_count(db, year)
  count = db.query("SELECT COUNT(*) FROM  `content_#{year}`").to_a[0]['COUNT(*)']
  return count.to_i
end

def get_patent_from_newpatent(year, start_from, num)
  begin
    patent_ids = @new_patent_db.query("SELECT `Patent_id` FROM content_#{year} ORDER BY `Index` ASC LIMIT #{start_from-1}, #{num}").to_a
  rescue => e
    puts "GET PATENT_ID index=#{start_from} from newpatent=>  Exception:#{e.to_s}"
    sleep(1)
    @mysql = Connect_mysql.new('chuya', '0514')
    @new_patent_db = @mysql.db('new_patent') #input/output db  
    retry
  end
  return patent_ids
end

def covert_to_query_str(patent_ids)
  queryStr = ""
  (0..patent_ids.count-1).each do |i|
  	if i != patent_ids.count-1
  		queryStr = queryStr + "'#{patent_ids[i]["Patent_id"]}',"
  	else
  		queryStr = queryStr + "'#{patent_ids[i]["Patent_id"]}'"
  	end
  end
  return queryStr
end

def check_exist_in_mypaper(year, patent_ids)
  patentidStr = covert_to_query_str(patent_ids)
  begin
    mypaperID = @mypaper_db.query("SELECT `Patent_id` FROM content_#{year} WHERE `Patent_id` IN (#{patentidStr}) ").to_a
  rescue => e
    puts "check_exist_in_mypaper =>  Exception:#{e.to_s}"
    sleep(1)
    @mysql = Connect_mysql.new('chuya', '0514')
    @new_patent_db = @mysql.db('new_patent') #input/output db  
    retry
  end

  return mypaperID
end

def update_exist_attr(year, patent_ids)
  patentidStr = covert_to_query_str(patent_ids)
  begin
    @new_patent_db.query("UPDATE content_#{year} SET `mypaper_exist` = 1 WHERE Patent_id IN (#{patentidStr}) ")
  rescue => e
    puts "Update exist_attr Patent_id:#{patentid}  =>  Exception:#{e.to_s}"
    sleep(1)
    @mysql = Connect_mysql.new('chuya', '0514')
    @new_patent_db = @mysql.db('new_patent') #input/output db  
    retry
  end
end

puts "Trace mypaper process start\n"
start_time = Time.now

@year = ARGV[0]
new_patent_count = total_count(@new_patent_db, @year)
mypaper_count = total_count(@mypaper_db, @year)
puts "#{@year} -> new_paper : #{new_patent_count}, mypaper : #{mypaper_count}"
# if new_patent_count > mypaper_count
(0..new_patent_count/100+1).each do |i|
	str = "Index : #{i*100+1} ~ #{i*100+100}, "
	patentids = get_patent_from_newpatent(@year, i*100+1, 100)
	exist_ids = check_exist_in_mypaper(@year, patentids)
    update_exist_attr(@year, exist_ids)
    str = str + "Exist Count : #{exist_ids.count}"
    puts str
	# exist_count = check_exist_in_mypaper(@year, patentid)
	# update_exist_attr(@year, patentid, exist_count)
	# puts "Index: #{i}, PatentID: #{patentid}, ExistCount: #{exist_count}"
end

puts "Process Duration: #{Time.now - start_time} seconds\n"
puts "Process end"

