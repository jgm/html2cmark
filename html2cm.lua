#!/usr/bin/env lua

package.path = "./?.lua;../?.lua;" .. package.path
package.cpath = "../?.so;" .. package.cpath

local optparse = require 'optparse'
local cmark = require 'cmark'
local builder = require 'cmark.builder'
local html2node = require 'html2node'

local spec = [[
html2cm 0.0
https://github.com/jgm/html2cmark

Usage: html2cm [options] [file..]

Convert HTML to CommonMark.

Options:

  --containers        Include HTML containers (e.g. div) around CommonMark
  --columns=NUMBER    Column width for wrapping (or 0 to preserve)
  --ignore=[TAG,...]  List of tags to ignore
  -V, --version       Version information
  -h, --help          This message
]]

local optparser = optparse(spec)

_G.arg, _G.opts = optparser:parse(_G.arg)

local inp
if #arg == 0 then
  inp = io.read("*all")
else
  local inpt = {}
  for _,f in ipairs(arg) do
    ok, msg = pcall(function() io.input(f) end)
    if ok then
      table.insert(inpt, io.read("*all"))
    else
      io.stderr:write("Could not open file '" .. f .. "': " .. msg .. '\n', 7)
      os.exit(1)
    end
  end
  inp = table.concat(inpt, "\n")
end


local doc, msg = html2node.parse_html(inp, opts)
if not doc then
  io.stderr:write(msg)
  os.exit(1)
end

local cm, msg = cmark.render_commonmark(doc, cmark.OPT_DEFAULT, opts.columns or 72)

if not cm then
  io.stderr:write(msg)
  os.exit(1)
end

io.write(cm)
