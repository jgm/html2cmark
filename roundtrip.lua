#!/usr/bin/env lua

package.path = "./?.lua;../?.lua;" .. package.path
package.cpath = "../?.so;" .. package.cpath

local cmark = require 'cmark'
local builder = require 'cmark.builder'
local html2node = require 'html2node'

local inp = io.read("*a")

local html = cmark.markdown_to_html(inp, #inp, cmark.OPT_DEFAULT)
local doc = html2node.parse_html(html)
local cm = cmark.render_commonmark(doc, cmark.OPT_DEFAULT, 72)
local html2 = cmark.markdown_to_html(cm, #cm, cmark.OPT_DEFAULT)

io.write(html2)

