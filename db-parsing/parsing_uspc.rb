require 'mysql2'
require 'timeout'
#File.open("parsing_uspc.log", "a") do |aFile|

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
								#log file
								#aFile.write( "[" + Time.now.to_s + "] insert #{row['Patent_id']}")
								#print out every found USPC(which should be unique) and INSERT each into table USPC
								uspcs.each do |uspc|
									#aFile.write( ",")
									uspc = uspc.strip
									s = "INSERT INTO `patentproject2012`.`USPC_#{year}` (`Patent_id`, `USPC_class`) 
												VALUES ( '#{row['Patent_id']}',  '#{uspc}'  )"
									if db.query("SELECT * FROM `uspc_#{year}` WHERE `Patent_id`='#{row['Patent_id']}'AND`uspc_class`='#{uspc}'").to_a[0].nil?
										db.query( s )
										#aFile.write( " #{uspc}")
									else
										print "uspc #{row['Patent_id']} #{uspc} exists\n"
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
								File.open("uspc_skipped_#{year}.log", "a") do |bFile|
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