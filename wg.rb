require 'net/http'
require 'open-uri'
require 'json'
catalog = JSON.parse(Net::HTTP.get("a.4cdn.org", "/wg/catalog.json"))
images = Array.new
urls  = Array.new

for page in catalog do
	for thread in page["threads"] do
		if thread["sticky"] == 1 then
			next
		end
		urls.push thread["no"] #unless thread["no"].class == "".class
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
end

index = 0
for image in images do
	index += 1
	puts "On image " + image + " " + index.to_s + "/" + urls.length.to_s
	out = open(image, 'w')
	out.write(open("https://i.4cdn.org/wg/" + image).read)
	out.close
end
