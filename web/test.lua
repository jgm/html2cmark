package.path='./?.lua;' .. package.path
local to_commonmark = require 'to_commonmark'
local connector = require "wsapi.mock"

local app = connector.make_handler(to_commonmark.run)

do
  local response, request = app:post("/", {html = "<em>hi</em>"}, {})
  assert(response.code                    == 200)
  assert(response.headers["Content-type"] == "text/plain; charset=UTF-8")
  assert(response.body                    == "*hi*\n")
end

