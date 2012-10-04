#!/usr/bin/env ruby
# encoding: UTF-8

require 'nokogiri'
require 'open-uri'
require_relative '../lib/connect_mysql'

# get the patent_id from mypaper(input_db)
def get_patent_id(input_db, query_year, query_index)
  query_limit = "LIMIT #{query_index-1}, 1"
  patent_id = input_db.query("SELECT Patent_id FROM content_#{query_year} ORDER BY Patent_id ASC #{query_limit}")
  return patent_id.to_a[0]['Patent_id']
end

# get the page from USPTO and parsing it to get what i need
def get_assignee(patent_id)
  # get the html page from USPTO	
  begin
    page = Nokogiri::HTML(open("http://patft.uspto.gov/netacgi/nph-Parser?Sect1=PTO1&Sect2=HITOFF&d=PALL&p=1&u=%2Fnetahtml%2FPTO%2Fsrchnum.htm&r=1&f=G&l=50&s1=#{patent_id}.PN.&OS=PN/#{patent_id}&RS=PN/#{patent_id}"))
  rescue => e
    puts "Patent_id:#{patent_id}  =>  Exception:#{e.to_s}"
    sleep(1)
    retry
  end

  # parsing the html page
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
  # return_data['result'] = -1(title not match), 
  #                          0(without assignee),
  #                          1(have assignee) 
  # return_data['data'] = [{'Assignee', 'Location'},.....]
  return return_data
end

##################################################################################
# MAIN
##################################################################################
# connect to mysql
mysql = Connect_mysql.new('chuya', '0514')
mypaper = mysql.db('mypaper') #input db
patentproject = mysql.db('patentproject2012') #output db

# parameter
query_year = ARGV[0]
query_start = ARGV[1].to_i  #start from number, the begining is 1 not 0
query_end = ARGV[2].to_i

# process start_time
start_time = Time.now

# some array for record in logfile
with_assignee, without_assignee, page_error = [], [], []

# logfile
logfile = File.open("log/assignee_#{query_year}_from_#{query_start}_to_#{query_end}.log", 'w')
logfile.write("Crawling Assignee from USPTO, start at #{start_time.to_s}\n")

# for_loop to crawl
(query_start..query_end).each do |i|
	# get the patent_id from mypaper(input_db)
	patent_id = get_patent_id(mypaper, query_year, i)
	puts "GET #{query_year} => Patent_id:#{patent_id}\n"
	# get the data from USPTO
	assignee_data = get_assignee(patent_id)
	# Insert data or not
	if assignee_data['result'] == -1
		page_error.push(patent_id)
		s = "Index:#{i} => Patent_id:#{patent_id} => Page error\n"
		puts s
		logfile.write(s)

	elsif assignee_data['result'] == 0
		without_assignee.push(patent_id)
		s = "Index:#{i} => Patent_id:#{patent_id} => Without Assignee\n"
		puts s
		logfile.write(s)
		# Insert null to DB
    	insert_time = 1
    	begin
    		patentproject.query("INSERT INTO assignee_#{query_year} (Patent_id, Assignee, Location)
                                 VALUES ('#{patent_id}', 'WITHOUT', 'WITHOUT') ")
    		# double check
    		dc = patentproject.query("SELECT Patent_id FROM assignee_#{query_year}
                                      WHERE Patent_id = '#{patent_id}' AND Assignee = 'WITHOUT'AND Location = 'WITHOUT' ")
    		if dc.to_a.count == 0
        		raise "Insert Failure"
      		end
      	rescue => e
      		s = "Index:#{i} => Patent_id:#{patent_id} => Exception:#{e.to_s}\n"
      		puts s
      		logfile.write(s)
      		sleep(1)
      		insert_time = insert_time + 1
      		if insert_time < 5
      			retry
      		end
      	end

	elsif assignee_data['result'] == 1
		with_assignee.push(patent_id)
		assignee_data['data'].each do |d|
			# prevent syntax error
			modify_assignee = d['Assignee'].gsub(/'/, "''")
        	modify_location = d['Location'].gsub(/'/, "''")
        	# Insert to DB
        	insert_time = 1
        	begin
        		patentproject.query("INSERT INTO assignee_#{query_year} (Patent_id, Assignee, Location)
                                     VALUES ('#{patent_id}', '#{modify_assignee}', '#{modify_location}') ")
        		# double check
        		dc = patentproject.query("SELECT Patent_id FROM assignee_#{query_year}
                                          WHERE Patent_id = '#{patent_id}' AND Assignee = '#{modify_assignee}'AND Location = '#{modify_location}' ")
        		if dc.to_a.count == 0
            		raise "Insert Failure"
          		end
          	rescue => e
          		s = "Index:#{i} => Patent_id:#{patent_id} => Exception:#{e.to_s}\n"
          		puts s
          		logfile.write(s)
          		sleep(1)
          		insert_time = insert_time + 1
          		if insert_time < 5
          			retry
          		end
          	end

          	s = "Index:#{i} => Patent_id:#{patent_id} => Assignee:#{d['Assignee']} => Location:#{d['Location']}\n"
          	puts s
          	logfile.write(s)
        end # end for each
    end # end if
end # end for


# all patent_id finish
end_time = Time.now
s = "with_assignee = #{with_assignee.count}\n"+
    "without_assignee = #{without_assignee.count}\n"+
    "page_error = #{page_error.count}\n"+
    "total = #{with_assignee.count+without_assignee.count+page_error.count}\n\n"+
    "Page Error Patent_id = #{page_error}\n\n"+
    "End time at: #{end_time.to_s}\n\n"+
    "Process Duration: #{end_time - start_time} seconds\n\n"
puts s
logfile.write(s)

puts "assignee_#{query_year} from #{query_start} to #{query_end} completed\n"









