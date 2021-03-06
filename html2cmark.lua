-- local inspect = require'inspect'.inspect
local gumbo = require'gumbo'
local builder = require'cmark.builder'
local cmark = require'cmark'

local phrasingNodes = {
  contains_only_phrasing_content = function(self, node)
    local child = node.firstChild
    while child do
      if not self:is_phrasing(child) then
        return false
      end
      child = child.nextSibling
    end
    return true
  end,
  is_phrasing = function(self, node)
    local nodename = node.nodeName
    local result = self[nodename]
    if result == true then
      return true
    elseif type(result) == 'function' then
      return result(self, node)
    else
      return false
    end
  end,
  A = function(self, node) return self:contains_only_phrasing_content(node) end,
  ABBR = true,
  AREA = function(_, node)
           return node.parentNode and node.parentNode.nodeName == 'MAP'
         end,
  AUDIO = true,
  B = true,
  BDI = true,
  BDO = true,
  BR = true,
  BUTTON = true,
  CANVAS = true,
  CITE = true,
  CODE = true,
  COMMAND = true,
  DATALIST = true,
  DEL = function(self, node)
          return self:contains_only_phrasing_content(node)
        end,
  DFN = true,
  EM = true,
  EMBED = true,
  I = true,
  IFRAME = true,
  IMG = true,
  INPUT = true,
  INS = function(self, node)
          return self:contains_only_phrasing_content(node)
        end,
  MARK = true,
  MATH = true,
  METER = true,
  NOSCRIPT = true,
  OBJECT = true,
  OUTPUT = true,
  PROGRESS = true,
  Q = true,
  RUBY = true,
  S = true,
  SAMP = true,
  SCRIPT = true,
  SELECt = true,
  SMALL = true,
  SPAN = true,
  STRONG = true,
  SUB = true,
  SUP = true,
  SVG = true,
  TEXTAREA = true,
  TIME = true,
  U = true,
  VIDEO = true,
  WBR = true,
  ["#text"] = true
}

local inlineContainer = {
  P = true,
  H1 = true,
  H2 = true,
  H3 = true,
  H4 = true,
  H5 = true,
  H6 = true,
}

local function is_phrasing_content(node)
  return phrasingNodes:is_phrasing(node)
end

local function is_block_content(node)
  return not phrasingNodes:is_phrasing(node)
end

local surround = {
    DIV = true,
    SECTION = true,
    MAIN = true,
    ARTICLE = true,
    HEADER = true,
    FOOTER = true
}

local function handleNode(node, opts)
  local nodeName = node.nodeName
  local skip = opts.skip or {}
  local ignore = opts.ignore or {}
  local parent = node.parentNode

  local contents = {}

  local attributes = node.attributes
  if attributes then
    for _,attribute in ipairs(attributes) do
      local attname = attribute.name
      local attvalue = attribute.value
      if attname == 'href' or attname == 'src' then
        contents.url = attvalue
      elseif attname == 'title' then
        contents.title = attvalue
      elseif attname == 'alt' and #contents == 0 then
        contents[1] = builder.text(attvalue)
      elseif attname == 'start' then
        contents.start = attvalue
      end
    end
  end

  if skip[nodeName] then
    return {}
  end

  local child = node.firstChild
  local all_text = true
  while child do
    local new = handleNode(child, opts)
    if type(new) == 'string' then
      if nodeName ~= 'OL' and nodeName ~= 'UL' then
        contents[#contents + 1] = new
      end
    else
      all_text = false
      contents[#contents + 1] = new
    end
    child = child.nextSibling
  end

  if not (phrasingNodes[nodeName] or inlineContainer[nodeName]) and
      phrasingNodes:contains_only_phrasing_content(node) then
    contents = {builder.paragraph(contents)}
  end

  if nodeName == 'OL' or nodeName == 'UL' then
    local tight = true
    child = node.firstChild
    while child do
      local subchild = child.firstChild
      while subchild do
        if subchild.nodeName == 'P' then
          tight = false
          break
        end
        subchild = subchild.nextSibling
      end
      child = child.nextSibling
    end
    contents.tight = tight
  end

  if nodeName == '#text' then
    local t = node.textContent
    local prevS = node.previousSibling
    local nextS = node.nextSibling
    if (not parent or
        is_block_content(parent)) or
        (prevS and (prevS.nodeName == 'BR' or is_block_content(prevS))) or
        (nextS and is_block_content(nextS)) then
      if (not prevS or
          prevS.nodeName == 'BR' or
          is_block_content(prevS)) then
          t = t:gsub('^[ \t\r\n]+','')
      end
      if (not nextS or
          is_block_content(nextS)) then
          t = t:gsub('[ \t\r\n]+$','')
      end
    end
    if string.len(t) > 0 then
      local buf = {}
      if t:match('^[\r\n]') then
        buf[#buf + 1] = builder.softbreak()
      end
      t:gsub('([^\r\n]+)([\r\n]*)', function(x, y)
          buf[#buf + 1] = builder.text(x)
          if #y > 0 then
            buf[#buf + 1] = builder.softbreak()
          end
      end)
      return buf
    else
      return {}
    end
  elseif nodeName == '#comment' then
    if opts.comments then
      local t = node.textContent
      return builder.html_block('<!--' .. t .. '-->')
    else
      return {}
    end
  elseif ignore[nodeName] then
    return contents
  elseif nodeName == 'HTML' then
    return contents
  elseif nodeName == 'BODY' then
    return contents
  elseif nodeName == 'HEAD' then
    return {}
  elseif nodeName == 'P' then
    return builder.paragraph(contents)
  elseif nodeName == 'BLOCKQUOTE' then
    if all_text then
      return builder.block_quote(builder.paragraph(contents))
    else
      return builder.block_quote(contents)
    end
  elseif nodeName == 'H1' then
    contents.level = 1
    return builder.heading(contents)
  elseif nodeName == 'H2' then
    contents.level = 2
    return builder.heading(contents)
  elseif nodeName == 'H3' then
    contents.level = 3
    return builder.heading(contents)
  elseif nodeName == 'H4' then
    contents.level = 4
    return builder.heading(contents)
  elseif nodeName == 'H5' then
    contents.level = 5
    return builder.heading(contents)
  elseif nodeName == 'H6' then
    contents.level = 6
    return builder.heading(contents)
  elseif nodeName == 'PRE' then
    local code = node.textContent
    local info = nil
    local codenode = node.firstChild
    while codenode and codenode.nodeName ~= 'CODE' do
      codenode = codenode.nextSibling
    end
    if not codenode then
      codenode = node
    end
    for _,attribute in ipairs(codenode.attributes) do
      if attribute.name == 'class' then
        info = attribute.value:gsub('language%-','')
      end
    end
    return builder.code_block{info = info, code}
  elseif nodeName == 'LI' then
    return builder.item(contents)
  elseif nodeName == 'UL' then
    return builder.bullet_list(contents)
  elseif nodeName == 'OL' then
    return builder.ordered_list(contents)
  elseif nodeName == 'BR' then
    return builder.linebreak()
  elseif nodeName == 'HR' then
    return builder.thematic_break()
  elseif nodeName == 'EM' or nodeName == 'I' then
    return builder.emph(contents)
  elseif nodeName == 'STRONG' or nodeName == 'B' then
    return builder.strong(contents)
  elseif nodeName == 'A' then
    return builder.link(contents)
  elseif nodeName == 'CODE' then
    return builder.code(node.textContent)
  elseif nodeName == 'IMG' then
    return builder.image(contents)
  else
    local attrString = ""
    if node.attributes then
      for _,attribute in ipairs(node.attributes) do
        attrString = attrString .. ' ' .. attribute.name .. '="' ..
                        attribute.escapedValue .. '"'
      end
    end

    if surround[nodeName] then
      if opts.containers then
        table.insert(contents, 1,
                   builder.html_block('<' .. node.localName .. attrString ..
                    '>'))
      end
      if opts.containers and not node.implicitEndTag then
        table.insert(contents,
                   builder.html_block('</' .. node.localName .. '>'))
      end
      return contents
    elseif is_phrasing_content(node) then
      table.insert(contents, 1,
                   builder.html_inline('<' .. node.localName .. attrString ..
                    '>'))
      if not node.implicitEndTag then
        table.insert(contents,
                   builder.html_inline('</' .. node.localName .. '>'))
      end
      return contents
    else
      if is_phrasing_content(node) or parent.nodeName == 'P' then
        return builder.html_inline(node.outerHTML)
      else
        return builder.html_block(node.outerHTML)
      end
    end
  end
end

local M = {}

local function get_content_node(node)
  if node.nodeName == 'MAIN' or
     (node.nodeName == 'DIV' and node.id == 'content') then
    return node
  else
    for _,n in ipairs(node.childNodes) do
      local res = get_content_node(n)
      if res then
        return res
      end
    end
  end
  return nil
end

function M.parse_html(htmlstring, opts)

  local html, msg
  html, msg = gumbo.parse(htmlstring, 4, 'BODY')
  if not html then
    return nil, msg
  end
  local children = {}

  -- try to find content node
  local content_node = get_content_node(html.documentElement) or
                        html.documentElement
  local nodes = content_node.childNodes

  for _,node in ipairs(nodes) do
    local new = handleNode(node, opts or {})
    if type(new) == 'table' then
      for _,n in ipairs(new) do
          children[#children + 1] = n
      end
    else
      children[#children + 1] = new
    end
  end

  local result
  result, msg = builder.document(children)
  if result then
    return result
  else
    return nil, msg
  end

end

local make_reference_links = function(doc)
  local urls = {}
  local links = {}
  local nextnum = 1
  for cur, entering, node_type in cmark.walk(doc) do
    if not entering and node_type == cmark.NODE_LINK then
      local url = cmark.node_get_url(cur)
      local title = cmark.node_get_title(cur)
      local num = urls[url] and urls[url][title]
      if not num then
        num = nextnum
        urls[url] = { [title] = num }
        links[num] = { url = url, title = title }
        nextnum = nextnum + 1
      end
      local ref = builder.custom_inline{
                      on_enter = '[',
                      on_exit = '][' .. num .. ']',
                      builder.get_children(cur) }
      local res = cmark.node_replace(cur, ref)
      cmark.node_free(cur)
      if not res then
        return nil, 'Could not replace link with reference'
      end
    end
  end
  local refs = {}
  for i,link in ipairs(links) do
    refs[#refs + 1] = '[' .. i .. ']: ' ..  link.url ..
        ((#link.title > 0 and (' "' .. link.title .. '"')) or '')
  end
  if #refs > 0 then
    cmark.node_append_child(doc, builder.custom_block{on_enter =
       table.concat(refs,'\n')})
  end
end

function M.to_commonmark(inp, opts)
  local doc, cm, msg
  doc, msg = M.parse_html(inp, opts)
  if not doc then
    return nil, msg
  end

  if opts.reference_links then
    make_reference_links(doc)
  end

  cm, msg = cmark.render_commonmark(doc, cmark.OPT_DEFAULT, opts.columns or 72)

  if not cm then
    return nil, msg
  end

  return cm
end

function M.to_xml(inp, opts)
  local doc, xml, msg
  doc, msg = M.parse_html(inp, opts)
  if not doc then
    return nil, msg
  end

  xml, msg = cmark.render_xml(doc, cmark.OPT_DEFAULT, opts.columns or 72)

  if not xml then
    return nil, msg
  end

  return xml
end


return M
