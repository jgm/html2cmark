package.path = "./?.lua;" .. package.path
package.cpath = "./?.so;" .. package.cpath

local cmark = require 'cmark'
local builder = require 'cmark.builder'
local html2node = require 'html2node'
local tests = require 'spec-tests'
local passed = 0
local failed = 0
local errored = 0

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
    io.write('------------------------------------- expected\n')
    io.write(oldhtml)
    io.write('------------------------------------- got\n')
    io.write(newhtml)
    io.write('\n')
  end
end

io.write(passed .. ' passed, ' .. failed .. ' failed, ' ..
         errored .. ' errored.\n')
os.exit(failed)

