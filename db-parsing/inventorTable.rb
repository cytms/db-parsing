require_relative '../lib/connect_mysql'

connect = Connect_mysql.new('chuya', '0514')
origin_db = connect.db('mypaper')
new_db = connect.db('patentproject2012') 

# temp = false

for i in 2000..2006
	puts i.to_s + " start"
#for i in 1976..2009
	tpapers = origin_db.query("select Patent_id, Inventors from `content_"+i.to_s+"`")
	#tpapers = origin_db.query("select Patent_id, Inventors from `content_"+i.to_s+"` where `Patent_id` = \"7332191\" limit 0,1")
	tpapers.each do |tpaper|
		# 跑一跑突然停止的時候可以使用
		# if temp == false
		# 	if tpaper['Patent_id'] == "7157363"
		# 		temp = true
		# 	end
		# 	next
		# end
# Chan; Man Tai "Teddy" (Kennedy Town, HK)
# Chu; Henry C. (Orange, CA)
		# puts tpaper['Patent_id'].to_s
		inventors = tpaper['Inventors'].to_s.split("),")
		
		temp = ""
		inventors.each do |inv|
			if inv.count("(") > 2 || (!(inv.to_s.include? "{") && inv.count("(")>1)	#若裡面有{，因為{}中會有一個()，所以一定要3個以上的(才表示location中有（）
				temp = temp + inv
				next
			end

			inv = inv.gsub("\"", "\\\"")
			if temp != ""	#location中有()
				inv = temp + ")," + inv
				temp = ""
				if inv.to_s.include? "{"	#若Name有{}且location有()	
					tmp1, tmp2 = inv.to_s.split(";")
					# puts tmp2
					tmp3, garbage, location1, location2, location3, location4, location5 = tmp2.to_s.split(/(\(|\))/)
					location = location1+location2+location3+location4+location5
					name = tmp1 + ";" + tmp3
				else
					name, garbage, location1, location2, location3, location4, location5 = inv.to_s.split(/(\(|\))/)
					location = location1+location2+location3+location4+location5
				end
			else
				if inv.to_s.include? "{" 
					tmp1, tmp2 = inv.to_s.split(";")
					tmp3, garbage, location = tmp2.to_s.split(/(\(|\))/)
					name = tmp1 + tmp3
				else
					name, garbage, location = inv.to_s.split(/(\(|\))/)
				end
			end
			
			begin
				new_db.query('insert into `patentproject2012`.`Inventor_'+i.to_s+'` (`Name`, `Patent_id`, `Location`) values ("'+name.to_s+'", "'+tpaper['Patent_id'].to_s+'", "'+location.to_s+'")')
				
			rescue => e
				puts tpaper['Patent_id'].to_s
				next
			end
		end
	end
end