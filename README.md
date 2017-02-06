## A scraper to get new wallpapers

Usage: `ruby wg-scraper.rb <download directory> [database]`

This program will scrape 4chan's /wg/ board for images.

About every 2 days, ~1200 of the ~8000 images get 404'd to make room for a new
batch. This program reads and writes to a database you specify so you can browse
more effectively. Initial download is about 6.5 gigabytes. After you go through
those, simply delete the downloaded images (but not the database) then re-run
the program to download the newest ~1200 images that were posted since your last
scrape

This means that, in theory, it should never show you the same wallpaper twice.

The content is ALL downloaded from 4chan, and the usual warnings come with that.
Guarenteed to be 100% edgy or your money back. For more, see `DISCLAIMER`

## Release notes

### 1.2

Major refactoring, same data isn't generated in three different places any more. Also, the database argument is now optional. The default if not specified is `db.json`

### 1.1

Now prefixes downloaded images with `threadno-index-`, should make your image viewer view threads in order, and the images in those threads in the order that they were posted
