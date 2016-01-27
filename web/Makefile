.PHONY: upload test deps clean

to_commonmark.lua: main.lua
	sed -n '/local html2cmark =/!p;//q' $< > $@
	echo 'local gethtml2cmark = function()' >> $@
	cat ../html2cmark.lua >> $@
	echo 'end' >> $@
	echo 'local html2cmark = gethtml2cmark()' >> $@
	sed -n '1,/local html2cmark =/!p' $< >> $@
	chmod +x $@

test:
	lua test.lua

deps:
	luarocks install --local amalg
	luarocks install --local wsapi
	luarocks install --local Lua-cURL

upload:
	scp to_commonmark.lua website:cgi-bin/
	# scp index.html index.js website:html/tmp334/

clean:
	rm to_commonmark.lua
