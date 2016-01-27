.PHONY: upload, test

test:
	lua test.lua

deps:
	luarocks install --local wsapi
	luarocks install --local Lua-cURL

upload:
	# scp index.html index.js website:html/tmp334/
	scp to_commonmark.lua website:cgi-bin/

