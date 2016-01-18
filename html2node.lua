-- local inspect = require'inspect'.inspect
local gumbo = require'gumbo'
local cmark = require'cmark'
local builder = require'cmark.builder'

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
  AREA = function(self, node)
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

local function is_phrasing_content(node)
  return phrasingNodes:is_phrasing(node)
end

local function is_block_content(node)
  return not phrasingNodes:is_phrasing(node)
end

local skipNode = {
    HEAD = true,
    NAV = true,
    HEADER = true,
    FOOTER = true
}

local surround = {
    DIV = true,
    SECTION = true,
    MAIN = true,
    ARTICLE = true
}

local function handleNode(node, opts)
  local nodeName = node.nodeName
  local parent = node.parentNode
  if skipNode[nodeName] then
    return {}
  end

  local child = node.firstChild
  local attributes = node.attributes
  local contents = {}
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
      return t
    else
      return {}
    end
  elseif nodeName == '#comment' then
    local t = node.textContent
    return builder.html_block('<!--' .. t .. '-->')
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
    if phrasingNodes:contains_only_phrasing_content(node) then
      return builder.item(builder.paragraph(contents))
    else
      return builder.item(contents)
    end
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

    if surround[nodeName] and opts.markdown_in_html then
      table.insert(contents, 1,
                   builder.html_block('<' .. node.localName .. attrString ..
                    '>'))
      if not node.implicitEndTag then
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

local html2node = {}

function html2node.parse_html(htmlstring, opts)

  local html = gumbo.parse(htmlstring, 4, 'HTML')
  local nodes = html.documentElement.childNodes
  local children = {}

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

  return builder.document(children)

end

return html2node
