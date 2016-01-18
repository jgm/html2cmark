#!/usr/bin/env lua

package.path = "./?.lua;../?.lua;" .. package.path
package.cpath = "../?.so;" .. package.cpath

local cmark = require 'cmark'
local builder = require 'cmark.builder'
local html2node = require 'html2node'

local inp = io.read("*a")

local doc, msg = html2node.parse_html(inp, {markdown_in_html = true})
if not doc then
  io.stderr:write(msg)
  os.exit(1)
end

local cm, msg = cmark.render_commonmark(doc, cmark.OPT_DEFAULT, 72)

if not cm then
  io.stderr:write(msg)
  os.exit(1)
end

io.write(cm)
