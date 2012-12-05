require 'mysql2'
require 'timeout'

db = Mysql2::Client.new(:host => '140.112.107.1', :username => 'chuya', :password=> '0514', :database => 'patentproject2012')
new_patent = Mysql2::Client.new(:host => '140.112.107.1', :username => 'chuya', :password=> '0514', :database => 'new_patent')

#some parameters
last = 600		#the last queried number of entry in content_#{year} #start from -number
number = 50 	#number of rows for each query
year = 2002#1975		#the last processing year
#table = "content_"	
tableorigin = "content_" #prefix


while ( year < 2003 ) #should be 2010 
	year = year + 1 #count from 1976 to 2009
	total_entries = db.query("SELECT COUNT( `Patent_id` ) FROM `patent_#{year}`").to_a[0]['COUNT( `Patent_id` )']
	print total_entries
	while ( last < total_entries )

		if (last+number)>total_entries
			last = total_entries
		else
			last = last + number
		end
		print last.to_s+"\n"
		
		begin
			Timeout::timeout(600){
    			res = db.query("SELECT `Patent_id` FROM `patent_#{year}` LIMIT #{last},#{number}") 	
			
				res.each do |row|	
					retrycount = 0
					begin
						Timeout::timeout(60){	
							#get title according to `Patent_id` in `patent`	
							source = new_patent.query("SELECT `Title` FROM `"+tableorigin+year.to_s+"` WHERE `Patent_id`='#{row['Patent_id']}'") 
							title = source.to_a[0]['Title'].nil? ? String.new : source.to_a[0]['Title'].gsub(/'/, "''")

							#stdout
							print row['Patent_id']
							#print title
							#puts "\n"

							if title.empty?
								title = "XXXXX"
								####add wierd value
							end

							s = "UPDATE patent_#{year} SET Title='#{title}' WHERE Patent_id='#{row['Patent_id']}'"
							if db.query("SELECT `Title` FROM `patent_#{year}` WHERE `Patent_id`='#{row['Patent_id']}'AND`Title`='#{title}'").to_a.empty?#.nil?
								db.query( s )
								print "updated!\n"
							else
								print "title #{row['Patent_id']} #{title} exists\n"
							end

						}
					rescue => ex
						print ex.message
						#reconnect to patentproject2012, new_patent
						begin
							db.close
							new_patent.close
							puts "Reconnecting to databases... "
							db = Mysql2::Client.new(:host => '140.112.107.1', :username => 'chuya', :password=> '0514', :database => 'patentproject2012')
		    				new_patent = Mysql2::Client.new(:host => '140.112.107.1', :username => 'chuya', :password=> '0514', :database => 'new_patent')
							puts "Reconnected! \n"
						rescue
							retry
						end

						#check whether the patent has been successfully inserted. If yes, then move on; otherwise retry (not more than 10 times)
						if db.query("SELECT * FROM `patent_#{year}` WHERE `Patent_id`='#{row['Patent_id']}'").to_a[0].nil?&&retrycount>10
							File.open("title_skipped_#{year}.log", "a") do |bFile|
								bFile.write( "#{row['Patent_id']}\n")
							end
							print "skip #{row['Patent_id']}\n"
						else
							retrycount += 1
							retry
						end
					end
				end

			}
		rescue Exception => e
			begin
				print ex.message
				#reconnect to mypaper
				puts "Reconnecting to source db(patent_#{year})... "
				db.close
				db = Mysql2::Client.new(:host => '140.112.107.1', :username => 'chuya', :password=> '0514', :database => 'patentproject2012')
				puts "Reconnected! \n"
			rescue
				retry
			end
			retry
		end
	end
last = 0 #resetting
end