package.path='./?.lua;' .. package.path
local to_commonmark = require 'to_commonmark'
local connector = require "wsapi.mock"

local app = connector.make_handler(to_commonmark.run)
local failed = 0

local function dotest(name, method, params, headers, expected)
  io.write(name .. '...')
  local response, request
  if method == 'GET' then
    response, request = app:get("/", params, headers)
  elseif method == 'POST' then
    response, request = app:post("/", params, headers)
  else
    assert(false)
  end
  if response.headers["Content-type"] ~= "text/plain; charset=UTF-8" then
    io.write('FAILED\nContent-type is ' ..
       response.headers["Content-type"] .. '\n')
    failed = failed + 1
    return false
  end
  for k,v in pairs(expected) do
    if response[k] ~= v then
      io.write('FAILED\n' .. k .. ' was "' .. response[k] ..
          '", expected "' .. v .. '"\n')
      failed = failed + 1
      return false
    end
  end
  io.write('OK\n')
  return true
end

dotest('POST with html', 'POST', {html = '<em>hi</em>'}, {},
  {code = 200, body = '*hi*\n'})
dotest('GET with html', 'GET', {html = '<em>hi</em>'}, {},
  {code = 200, body = '*hi*\n'})

os.exit(failed)
