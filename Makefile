
.PHONY: deploy json test

test:
	./node_modules/.bin/mocha \
		--compilers coffee:coffee-script/register \
		--reporter dot

pages:
	grunt coffee sass
	grunt assemble
	grunt ical

json:
	php misc/export_jams.php 2011 > jams/2011.json
	php misc/export_jams.php 2012 > jams/2012.json
	php misc/export_jams.php 2013 > jams/2013.json
	php misc/export_jams.php 2014 > jams/2014.json
	php misc/export_jams.php 2015 > jams/2015.json

deploy:
	rsync -RrvuzL index.html *.ics *.js *.css jams/ font/ tags/ leaf@leafo.net:www/compohub.net
