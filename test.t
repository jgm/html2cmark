#!/usr/bin/env lua
require 'Test.More'

package.path = "./?.lua;" .. package.path
package.cpath = "./?.so;" .. package.cpath

local cmark = require 'cmark'
local builder = require 'cmark.builder'
local html2node = require 'html2node'
local tests = require 'spec-tests'

for _,test in ipairs(tests) do
  local oldhtml = test.html
  local doc  = html2node.parse_html(oldhtml, cmark.OPT_DEFAULT)
  local newhtml = cmark.render_html(doc, cmark.OPT_DEFAULT)
  is(newhtml, oldhtml, "example " .. tostring(test.example) ..
         " (lines " .. tostring(test.start_line) .. " - " ..
         tostring(test.end_line) .. ")")
end

done_testing()
