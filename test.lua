package.path = "./?.lua;" .. package.path
package.cpath = "./?.so;" .. package.cpath

local cmark = require 'cmark'
local builder = require 'cmark.builder'
local html2cmark = require 'html2cmark'
local tests = require 'spec-tests'
local passed = 0
local failed = 0
local errored = 0
local skipped = 0

local skip = { [592] = true
             , [603] = true
             , [604] = true }

for num,test in ipairs(tests) do
  if skip[num] then
    skipped = skipped + 1
  else
    local oldhtml = test.html
    local doc  = html2cmark.parse_html(oldhtml, {markdown_in_html = true})
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
end

io.write(passed .. ' passed, ' .. failed .. ' failed, ' ..
         errored .. ' errored, ' .. skipped .. ' skipped.\n')
os.exit(failed)

