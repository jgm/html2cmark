#!/home/website/.luarocks/bin/wsapi.cgi

-- Usage: curl http://johnmacfarlane.net/cgi-bin/html2cmark.cgi -F html=@papers.html

local _M = {}
local wsapi = require 'wsapi'
local request = require 'wsapi.request'

local html2cmark = require 'html2cmark'

function _M.run(wsapi_env)

  local headers = { ["Content-type"] = "text/plain" }

  local req = request.new(wsapi_env)

  local html = req.POST.html.contents or req.POST.html
  local opts = {}

  local doc, msg = html2cmark.parse_html(html, opts)
  if not doc then
    return 500, headers, msg
  end

  local cm, msg = cmark.render_commonmark(doc, cmark.OPT_DEFAULT, opts.columns or 72)

  local function cm_text()
    coroutine.yield(cm)
  end

  return 200, headers, coroutine.wrap(cm_text)
  
end

return _M
