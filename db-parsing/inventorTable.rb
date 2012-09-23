require_relative '../lib/connect_mysql'

connect = Connect_mysql.new('chuya', '0514')
origin_db = connect.db('mypaper')
new_db = connect.db('patentproject2012') 

for i in 2007..2007
#for i in 1976..2009
	tpapers = origin_db.query("select Patent_id, Inventors from `content_"+i.to_s+"`")
	#puts "select Patent_id, Inventors from `uspto_"+i.to_s+"`"
	tpapers.each do |tpaper|
		inventors = tpaper['Inventors'].to_s.split("),")
		# puts temp
		# inventors = temp[0].to_s.split(";")
		# inventors[0] = inventors[0].to_s.sub("Inventors:", "")
		inventors.each do |inv|
			begin
				name, garbage, location = inv.to_s.split(/(\(|\))/)

				# if inv.include? "("
				# 	name = inv.split("(")[0]
				# end
				# inv = inv.strip
				# puts inv
				new_db.query('insert into `patentproject2012`.`Inventor_2007` (`Name`, `Patent_id`, `Location`) values ("'+name.to_s+'", "'+tpaper['Patent_id'].to_s+'", "'+location.to_s+'")')
			rescue => e
				print e.message
				retry
			end
		end
	end
end