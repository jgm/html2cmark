#!/home/website/.luarocks/bin/wsapi.cgi

-- Usage: curl http://johnmacfarlane.net/cgi-bin/html2cmark.cgi -F html=@papers.html

local _M = {}
local wsapi = require 'wsapi'
local request = require 'wsapi.request'
local curl = require 'cURL'

local html2cmark = require 'html2cmark'

function _M.run(wsapi_env)

  local headers = { ["Content-type"] = "text/plain; charset=UTF-8" }

  local req = request.new(wsapi_env)

  local html, msg

  local url = req.params.url
  if url then
    curl.easy()
      :setopt_url(url)
      :setopt(curl.OPT_FOLLOWLOCATION, true)
      :setopt_writefunction(function(x)
        if html then html = html .. x else html = x end
      end)
      :perform()
      :close()
    if not html then
      return 500, headers, 'Could not retrieve HTML from ' .. url
    end
  else
    html = req.POST.html.contents or req.params.html
  end


  local opts = {ignore="script"}

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
