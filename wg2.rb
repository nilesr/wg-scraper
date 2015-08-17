require 'net/http'
require 'open-uri'
require 'digest'
require 'json'
if ARGV.length != 2 then
	puts "Usage: ruby wg2.rb imagedir database"
end
puts "Grabbing thread index"
imagesdir = ARGV[0]
database = ARGV[1]
catalog = JSON.parse(Net::HTTP.get("a.4cdn.org", "/wg/catalog.json"))
images = Array.new
urls  = Array.new

if imagesdir[-1] == "/"
	imagesdir = imagesdir[0...-1]
end

# Assertions
if File.exists? imagesdir and not File.directory? imagesdir then
	puts "Images directory " + imagesdir + " is not a directory"
	fail
end
if File.exists? database and File.directory? database then
	puts "Database " + database + " is actually a directory"
	fail
end
if File.exists? database then
	begin
		db = JSON.parse(open(database).read())
	rescue
		puts "Unable to parse database. Continue [Y/n]? "
		$stdout.flush
		if gets.chomp.upcase == "Y" then
			db = [[],[]]
		else
			puts "Unable to parse database, not overwriting."
			fail
		end
	end
else
	db = [[],[]]
end 
for page in catalog do
	for thread in page["threads"] do
		next if thread["sticky"] == 1
		urls.push thread["no"]
	end
end

index = 0
for url in urls do
	index += 1
	puts "On url " + url.to_s + " " + index.to_s + "/" + urls.length.to_s
	page = JSON.parse(Net::HTTP.get("a.4cdn.org", "/wg/thread/" + url.to_s + ".json"))
	for post in page["posts"] do
		if post.include? "filename" then
			images.push post["tim"].to_s + post["ext"]
		end
	end
	sleep 0.01 # Official specifications require that we limit ourselves to 100 requests per second
	# This doesn't actually do that because we don't run multiple connections at the same time, but better safe then sorry
end

puts "Eliminating duplicates, please wait"
sizea = images.length
for image in images do
	images -= [image] if db[1].include? image
end
puts "Eliminated " + (sizea - images.length).to_s + " duplicates"

index = 0
for image in images do
	retries = 0
	index += 1
	puts "On image " + image + " " + index.to_s + "/" + images.length.to_s
	while retries < 3 do
		retries += 1
		begin
			out = open(imagesdir + "/" + image, 'w')
			out.write(open("https://i.4cdn.org/wg/" + image).read)
		rescue
			puts "Download of image " + image + " failed. Retrying (" + retries.to_s + "/3)"
		else
			# Add to database
			db[1].push image
			break
		ensure
			out.close unless out.nil?
		end
	end
	if retries == 3 then
		puts "Download of image " + image + " failed. The image will not be added to the database."
	end
end

puts "Deleting downloaded duplicates by md5"
for	image in images do
	imagepath = imagesdir + "/" + image
	md5 = Digest::MD5.file(imagepath)
	if db[0].include? md5
		puts "Deleting duplicate image " + image
		File.delete imagepath
	else
		db[0].push md5
	end
end

puts "Writing out new database"
out = open(database, 'w')
out.write JSON.generate(db)
out.close
puts "Download complete"
