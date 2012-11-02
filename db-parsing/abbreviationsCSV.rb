require 'rubygems'
require 'net/http'
require 'nokogiri'
require 'open-uri'
require 'json'
require 'pp'
#MAX_ATTEMPTS = 5

def get_html( path )
	begin
		sleep(200.0/1000.0)
		# Get HTML of uri
		uri = 'http://www.abbreviations.com/acronyms/FIRMS/'+path
		doc = Nokogiri::HTML(open(uri))

		puts "HTTP GET Request #{uri}"
		doc
	rescue Exception => ex
	#	log.error "Error: #{ex}"
	#	attempts = attempts + 1
		retry #if(attempts < MAX_ATTEMPTS)
	end
end	

# Get html of the first page
doc = get_html( '' )
page = 1
index = doc.xpath('//div[@class="pager"]/a/text()').count
max_page_num = doc.xpath('//div[@class="pager"]/a/text()')[index-2].content.to_i

#output = Array.new()
File.open('abbreviations.txt', 'w') do |f|

	while (page <= max_page_num)

		doc = get_html( page.to_s )
		# Get abbr. list of current page
		rows = doc.xpath('//table[@class="tdata"]/tbody/tr')
		i = 0
		rows.each do |row|
			abbr = row.xpath('//td[@class="tal tm"]/a/text()')[ i ]
			name = row.xpath('//td[@class="tal dm"]/text()')[ i ]
			#output.push({"abbreviation"=>abbr, "name"=>name})
			f.write( abbr.to_s+'|'+name.to_s+'=' )

			i = i + 1
		end
		#move to next page
		page = page + 1
	end

	#json = output.to_json
	#empls = JSON.parse(json)
	#pp empls
	#File.open('abbreviations.json', 'w') { |f| f.write(json) }
end

#print "Total entries: " + output.count.to_s + "\n"