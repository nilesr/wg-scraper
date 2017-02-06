require 'net/http'
require 'open-uri'
require 'digest'
require 'json'
if ARGV.length != 1 or ARGV.length != 2 then
	puts "Usage: ruby wg2.rb <imagedir> [database]"
	fail
end
puts "Grabbing thread index"
imagesdir = ARGV[0]
database = "db.json"
if ARGV.length == 2 then
	database = ARGV[1]
end
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
		puts "Unable to parse database. Overwrite with a new empty one? [y/N]? "
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
	in_thread = 0
	for post in page["posts"] do
		if post.include? "filename" then
			images.push [post["tim"].to_s + post["ext"],imagesdir + "/" + index.to_s.rjust(urls.length.to_s.length, "0") + "-" + in_thread.to_s.rjust(page["posts"].length.to_s.length,"0") + "-"] # 3 digits because the post limit is 355 or something
			in_thread += 1;
		end
	end
	sleep 0.01 # Official specifications require that we limit ourselves to 100 requests per second
	# This doesn't actually do that because we don't run multiple connections at the same time, but better safe then sorry
end

puts "Eliminating previously downloaded images, please wait"
sizea = images.length
for image_array in images do
	images -= [image_array] if db[1].include? image_array[0]
end
puts "Eliminated " + (sizea - images.length).to_s + " previously downloaded images"

index = 0
for image_array in images do
	index = index + 1
	retries = 0
	puts "On image " + image_array[0] + " " + index.to_s + "/" + images.length.to_s
	while retries < 3 do
		retries += 1
		begin
			out = open(image_array[1] + image_array[0], 'w')
			out.write(open("https://i.4cdn.org/wg/" + image_array[0]).read)
		rescue
			puts "Download of image " + image_array[0] + " failed. Retrying (" + retries.to_s + "/3)"
		else
			# Add to database
			db[1].push image_array[0]
			break
		ensure
			out.close unless out.nil?
		end
	end
	if retries == 3 then
		puts "Download of image " + image_array[0] + " failed. The image will not be added to the database."
	end
end

puts "Deleting downloaded duplicates by md5"
for	image_array in images do
	imagepath = image_array[1] + image_array[0]
	if not File.exists? imagepath then
		puts "Warning: Image " + imagepath + " does not exist, but it should"
		puts "We will not be able to compare the MD5 of this image to the database"
		next
	end
	md5 = Digest::MD5.file(imagepath)
	if db[0].include? md5
		puts "Deleting duplicate image " + image_array[0]
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
