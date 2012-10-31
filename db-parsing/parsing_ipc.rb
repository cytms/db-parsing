require 'mysql2'
require 'timeout'
#File.open("parsing_ipc.log", "a") do |aFile|

    db = Mysql2::Client.new(:host => '140.112.107.1', :username => 'chuya', :password=> '0514', :database => 'patentproject2012')
    #mypaper = Mysql2::Client.new(:host => '140.112.107.1', :username => 'chuya', :password=> '0514', :database => 'mypaper')
    patent_value = Mysql2::Client.new(:host => '140.112.107.1', :username => 'chuya', :password=> '0514', :database => 'patent_value')

    #some parameters
    last = -50		#the last queried number of entry in content_#{year} #start from -number
    number = 50 	#number of rows for each query
    year = 2007#1975		#the last processing year
    #table = "content_"	
    tableorigin = "uspto_" #prefix


    while ( year < 2008 ) #should be 2010 
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
								#get data according to `Patent_id` in `patent`	
								source = patent_value.query("SELECT `Current U.S. Class` FROM `"+tableorigin+year.to_s+"` WHERE `Patent_id`='#{row['Patent_id']}'") 
								#parse IPC list by "Current International Class:" and "Field of Search:"
								ipctext = source.to_a[0]['Current U.S. Class'].split("Current International Class:")[1].nil? ? String.new : source.to_a[0]['Current U.S. Class'].split("Current International Class:")[1].split("Field of Search:")[0]

								#tokenize by /&nbsp\(.{0,8}\);?/ ("&nbsp" followed with 0~8 ".", and either end with ";"), or simply a ";"
								ipcs = ipctext.strip.split(/&nbsp\(.{0,8}\);?|;/).uniq
=begin

								if ipctext.length == 0
									File.open("ipc_empty_#{year}.log", "a") do |bFile|
										bFile.write( "#{row['Patent_id']}\n")
									end
								end
=end


								#stdout
								print row['Patent_id']
								print ipcs.to_s
								puts "\n"
								#log file
								#aFile.write( "[" + Time.now.to_s + "] insert #{row['Patent_id']}")
								#print out every found IPC(which should be unique) and INSERT each into table IPC
								if ipcs.empty?
									ipcs[0] = "XXXXX"
									####add wierd value
								end
								ipcs.each do |ipc|
									#aFile.write( ",")
									ipc = ipc.strip
									s = "INSERT INTO `patentproject2012`.`IPC_#{year}` (`Patent_id`, `IPC_class`) 
												VALUES ( '#{row['Patent_id']}',  '#{ipc}'  )"
									if db.query("SELECT * FROM `ipc_#{year}` WHERE `Patent_id`='#{row['Patent_id']}'AND`IPC_class`='#{ipc}'").to_a[0].nil?
										db.query( s )
										#aFile.write( " #{ipc}")
									else
										print "ipc #{row['Patent_id']} #{ipc} exists\n"
									end
								end	
								#aFile.write( "\n")
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
								File.open("ipc_skipped_#{year}.log", "a") do |bFile|
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
#end