## A scraper to get new wallpapers
This program will scrape 4chan's /wg/ board for images.

About every 2 days, ~1200 of the ~8000 images get 404'd to make room for a new
batch. This program reads and writes to a database you specify so you can browse
more effectively. Initial download is about 6.5 gigabytes. After you go through
those, simply delete the downloaded images (but not the database) then re-run
the program to download the newest ~1200 images.

This means that, in theory, it should never show you the same wallpaper twice.

The content is ALL downloaded from 4chan, and the usual warnings come with that.
Guarenteed to be 100% edgy or your money back. For more, see `DISCLAIMER`
