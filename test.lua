package.path = "./?.lua;" .. package.path
package.cpath = "./?.so;" .. package.cpath

local diff = require'diff'
local cmark = require 'cmark'
local builder = require 'cmark.builder'
local html2node = require 'html2node'
local tests = require 'spec-tests'
local passed = 0
local failed = 0
local errored = 0

local diffs = io.open("diffs.html", "w")
diffs:write([[
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<style type="text/css">
pre del { background-color: red }
pre ins { background-color: yellow }
</style>
</head>
<body>
]])

for num,test in ipairs(tests) do
  local oldhtml = test.html
  local doc  = html2node.parse_html(oldhtml, cmark.OPT_DEFAULT)
  local newhtml = cmark.render_html(doc, cmark.OPT_DEFAULT)
  if not newhtml then
    errored = errored + 1
  elseif newhtml == oldhtml then
    passed = passed + 1
  else
    failed = failed + 1
    io.write('FAILED test ' .. num .. '\n')
    diffs:write('<p>Example ' .. num .. '</p>\n<pre>')
    diffs:write(diff.diff(oldhtml, newhtml):to_html())
    diffs:write('</pre>\n')
  end
end

io.write(passed .. ' passed, ' .. failed .. ' failed, ' ..
         errored .. ' errored.\n')
io.write('Diffs written to diffs.html\n')
diffs:write('</body>\n</html>\n')
diffs:close()
os.exit(failed)

