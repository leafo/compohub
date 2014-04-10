
.PHONY: deploy

jams.all.json::
	php misc/export_jams.php > $@

deploy:
	rsync -RrvuzL index.html *.js *.css jams.all.json font/ leaf@leafo.net:www/jamhub
