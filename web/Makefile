.PHONY: upload, test

to_commonmark.lua: main.lua
	LUA_PATH="../?.lua;$$LUA_PATH" amalg.lua -o $@ -s $< html2cmark wsapi wsapi.request cURL

test:
	lua test.lua

deps:
	luarocks install --local amalg
	luarocks install --local wsapi
	luarocks install --local Lua-cURL

upload:
	scp to_commonmark.lua website:cgi-bin/
	# scp index.html index.js website:html/tmp334/

