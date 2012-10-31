###This ruby program parse 
###a patent(Filed date, Issued date, Abstract, Description, Summary and claims) into patent_[year]
###the patent's IPC number(s) starting with alphabets into IPC_[year]
###the patent's USPC number into uspc_[year]

require 'mysql2'
require	'timeout'

#database connection
db = Mysql2::Client.new(:host => '140.112.107.1', :username => 'chuya', :password=> '0514', :database => 'patentproject2012')
mypaper = Mysql2::Client.new(:host => '140.112.107.1', :username => 'chuya', :password=> '0514', :database => 'mypaper')
patent_value = Mysql2::Client.new(:host => '140.112.107.1', :username => 'chuya', :password=> '0514', :database => 'patent_value')

#some parameters
last = 1590		#the last queried number of entry in content_#{year}  #182815 (7301016)XX #start from -number
number = 30 	#number of rows for each query
year = 2002		#the last processing year
table = "content_"	#prefix
tableorigin = "uspto_"

while ( year < 2003 ) #should be 2010 
	year = year + 1 #count from 1976 to 2009
	total_entries =  mypaper.query("SELECT COUNT( `Patent_id` ) FROM `content_"+year.to_s+"` ").to_a[0]['COUNT( `Patent_id` )']
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
				res = mypaper.query("SELECT `Patent_id`,`Issued_Date`, `Issued_Year`,`Abstract`,`Claims`,`Description`,`Summary` FROM `"+table+year.to_s+"` LIMIT #{last},#{number}") #LIMIT 0,30	
			

				res.each do |row|
					retrycount = 0
					begin
						Timeout::timeout(60){
							#create new patent entry
							if db.query("SELECT * FROM `patent_#{year}` WHERE `Patent_id`='#{row['Patent_id']}'").to_a[0].nil?
								if row['Patent_id'].index(/^D/)								
									#ignore design patent(id="D...")
									print row['Patent_id']+"ignored\n"
								else
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

									############IPC insertion############
									#get data according to `Patent_id` in `patent`	
									source = patent_value.query("SELECT `Current U.S. Class` FROM `"+tableorigin+year.to_s+"` WHERE `Patent_id`='#{row['Patent_id']}'") 
									#parse IPC list by "Current International Class:" and "Field of Search:"
									ipctext = source.to_a[0]['Current U.S. Class'].split("Current International Class:")[1].nil? ? String.new : source.to_a[0]['Current U.S. Class'].split("Current International Class:")[1].split("Field of Search:")[0]

									#tokenize by /&nbsp\(.{0,8}\);?/ ("&nbsp" followed with 0~8 ".", and either end with ";"), or simply a ";"
									ipcs = ipctext.strip.split(/&nbsp\(.{0,8}\);?|;/).uniq

									#stdout
									print row['Patent_id']
									print ipcs.to_s
									puts "\n"

									#print out every found IPC(which should be unique) and INSERT each into table IPC
									if ipcs.empty?
										ipcs[0] = "XXXXX"
										####add wierd value
									end
									ipcs.each do |ipc|
										if ipc.index(/[a-zA-Z]/)
											ipc = ipc.strip
											s = "INSERT INTO `patentproject2012`.`IPC_#{year}` (`Patent_id`, `IPC_class`) 
														VALUES ( '#{row['Patent_id']}',  '#{ipc}'  )"
											if db.query("SELECT * FROM `ipc_#{year}` WHERE `Patent_id`='#{row['Patent_id']}'AND`IPC_class`='#{ipc}'").to_a[0].nil?
												db.query( s )
											else
												print "ipc #{row['Patent_id']} #{ipc} exists\n"
											end
										else#ignore non-alphabet
										end
									end	
									###########end of IPC insertion##############

									###########USPC insertion####################
																	#get data according to `Patent_id` in `patent`	
									source = patent_value.query("SELECT `Current U.S. Class` FROM `"+tableorigin+year.to_s+"` WHERE `Patent_id`='#{row['Patent_id']}'") 
									#parse uspc list by "Current U.S. Class:" and "Current International Class:"
									uspctext = source.to_a[0]['Current U.S. Class'].split("Current U.S. Class:")[1].nil? ? String.new : source.to_a[0]['Current U.S. Class'].split("Current U.S. Class:")[1].split("Current International Class:")[0]

									#tokenize by /&nbsp\(.{0,8}\);?/ ("&nbsp" followed with 0~8 ".", and either end with ";"), or simply a ";"
									uspcs = uspctext.strip.split(/&nbsp\(.{0,8}\);?|;/).uniq

									if uspctext.length == 0
										File.open("uspc_empty_#{year}.log", "a") do |bFile|
											bFile.write( "#{row['Patent_id']}\n")
										end
									end

									#stdout
									print row['Patent_id']
									print uspcs.to_s
									puts "\n"

									#print out every found USPC(which should be unique) and INSERT each into table USPC
									uspcs.each do |uspc|
										uspc = uspc.strip
										s = "INSERT INTO `patentproject2012`.`USPC_#{year}` (`Patent_id`, `USPC_class`) 
													VALUES ( '#{row['Patent_id']}',  '#{uspc}'  )"
										if db.query("SELECT * FROM `uspc_#{year}` WHERE `Patent_id`='#{row['Patent_id']}'AND`uspc_class`='#{uspc}'").to_a[0].nil?
											db.query( s )
										else
											print "uspc #{row['Patent_id']} #{uspc} exists\n"
										end
									end	
									###########end of USPC insertion###########
								end
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
							File.open("patent_skipped_#{year}.log", "a") do |bFile|
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
	end
	last = 0 #resetting
	#current year's patent done
end