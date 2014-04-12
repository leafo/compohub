
.PHONY: deploy json test

test:
	./node_modules/.bin/mocha \
		--compilers coffee:coffee-script/register \
		--reporter dot

json:
	php misc/export_jams.php 2011 > jams/2011.json
	php misc/export_jams.php 2012 > jams/2012.json
	php misc/export_jams.php 2013 > jams/2013.json
	php misc/export_jams.php 2014 > jams/2014.json

deploy:
	rsync -RrvuzL index.html *.js *.css jams/ font/ leaf@leafo.net:www/compohub
