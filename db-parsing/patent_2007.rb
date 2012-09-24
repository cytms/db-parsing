require 'mysql2'
require	'timeout'
#File.open("parsing_patent_withfiled_2007.log", "a") do |aFile|

	#database connection
    db = Mysql2::Client.new(:host => '140.112.107.1', :username => 'chuya', :password=> '0514', :database => 'patentproject2012')
    mypaper = Mysql2::Client.new(:host => '140.112.107.1', :username => 'chuya', :password=> '0514', :database => 'mypaper')
    patent_value = Mysql2::Client.new(:host => '140.112.107.1', :username => 'chuya', :password=> '0514', :database => 'patent_value')

    #some parameters
    last = 19320		#the last queried number of entry in content_#{year}
    number = 30 	#number of rows for each query
    year = 2006		#the last processing year
    table = "content_"	#prefix
    tableorigin = "uspto_"

    while ( year < 2007 ) #should be 2010 
    	year = year + 1 #count from 1976 to 2009
    	total_entries =  mypaper.query("SELECT COUNT( `Patent_id` ) FROM `content_"+year.to_s+"` ").to_a[0]['COUNT( `Patent_id` )']
    	print total_entries
    	while ( last < total_entries )
    		begin 
    			Timeout::timeout(60){
					res = mypaper.query("SELECT `Patent_id`,`Issued_Date`, `Issued_Year`,`Abstract`,`Claims`,`Description`,`Summary` FROM `"+table+year.to_s+"` LIMIT #{last},#{number}") #LIMIT 0,30	
				

					res.each do |row|
						retrycount = 0
						begin
							Timeout::timeout(60){
								#create new patent entry
								if db.query("SELECT * FROM `patent_#{year}` WHERE `Patent_id`='#{row['Patent_id']}'").to_a[0].nil?								
									#parsing date format
									date = Date.parse( row['Issued_Date'].to_s + String.new(" ")+ row['Issued_Year'].to_s ).to_s

									#config character ' which appear in contents
									abstract = row['Abstract'].nil? ? String.new : row['Abstract'].gsub(/'/, "''")
									claims = row['Claims'].nil? ? String.new : row['Claims'].gsub(/'/, "''")
									description = row['Description'].nil? ? String.new : row['Description'].gsub(/'/, "''")
									summary = row['Summary'].nil? ? String.new : row['Summary'].gsub(/'/, "''")
									#ternary operation --a.nil? ? String.new : a.gsub("a", "aha")
									
									#parse filed date from patent_value
									res_in = patent_value.query("SELECT `Inventors` FROM `"+tableorigin+year.to_s+"` WHERE `Patent_id`='#{row['Patent_id']}'") 
									fileddate = res_in.to_a[0]['Inventors'].split("Filed:")[1].nil? ? String.new : Date.parse( res_in.to_a[0]['Inventors'].split("Filed:")[1] ).to_s
				
									s = "INSERT INTO `patentproject2012`.`patent_#{year}` (`Patent_id`, `Issued_Date`,`Filed_Date`,`Abstract`,
													`Claims`,
													`Description`,
													`Summary`) 
												VALUES (
													'#{row['Patent_id']}',
													'#{date}',
													'#{fileddate}',
													'#{abstract}',
													'#{claims}',
													'#{description}',
													'#{summary}'	)"
									
									#insert new entry into table
									print "Inserting...#{row['Patent_id']}"
										db.query( s )
									print "Done. "

									print row['Patent_id']+"/"+date+"/"+fileddate+"\n"#+abstract+claims+description+summary
									#aFile.write( "[" + Time.now.to_s + "] insert #{row['Patent_id']}/ #{date} / #{fileddate}\n")
									#previous = row['Patent_id']
								else
									print row['Patent_id']+"exists\n"
								end
							}
						rescue => ex
							print ex.message
							
							#reconnect to patentproject2012, patent_value
							begin
								
								db.close
								patent_value.close
								puts "Reconnecting to databases... "
								db = Mysql2::Client.new(:host => '140.112.107.1', :username => 'chuya', :password=> '0514', :database => 'patentproject2012')
			    				patent_value = Mysql2::Client.new(:host => '140.112.107.1', :username => 'chuya', :password=> '0514', :database => 'patent_value')
								puts "Reconnected! \n"
							rescue
								retry
							end

							#check whether the patent has been successfully inserted. If yes, then move on; otherwise retry (not more than 10 times)
							if db.query("SELECT * FROM `patent_#{year}` WHERE `Patent_id`='#{row['Patent_id']}'").to_a[0].nil?&&retrycount>10
								File.open("patent_skipped_2007.log", "a") do |bFile|
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
			rescue => ex
				begin
					print ex.message
					#reconnect to mypaper
					puts "Reconnecting to source db(mypaper)... "
					mypaper.close
					mypaper = Mysql2::Client.new(:host => '140.112.107.1', :username => 'chuya', :password=> '0514', :database => 'mypaper')
					puts "Reconnected! \n"
				rescue
					retry
				end

				retry
			end


	
			last = last + number
			print last.to_s + "\n"
		end
		last = 0 #resetting
		#current year's patent done
    end
#end #end aFile