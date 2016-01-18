-- local inspect = require'inspect'.inspect
local gumbo = require'gumbo'
local cmark = require'cmark'
local builder = require'cmark.builder'

local blockNode = {
  HTML = true,
  HEAD = true,
  ARTICLE = true,
  MAIN = true,
  NAV = true,
  HEADER = true,
  ASIDE = true,
  HGROUP = true,
  BLOCKQUOTE = true,
  HR = true,
  IFRAME = true,
  BODY = true,
  LI = true,
  MAP = true,
  BUTTON = true,
  OBJECT = true,
  CANVAS = true,
  OL = true,
  CAPTION = true,
  OUTPUT = true,
  COL = true,
  P = true,
  COLGROUP = true,
  PRE = true,
  DD = true,
  PROGRESS = true,
  DIV = true,
  SECTION = true,
  DL = true,
  TABLE = true,
  TD = true,
  DT = true,
  TBODY = true,
  EMBED = true,
  TEXTAREA = true,
  FIELDSET = true,
  TFOOT = true,
  FIGCAPTION = true,
  TH = true,
  FIGURE = true,
  THEAD = true,
  FOOTER = true,
  TR = true,
  FORM = true,
  UL = true,
  H1 = true,
  H2 = true,
  H3 = true,
  H4 = true,
  H5 = true,
  H6 = true,
  VIDEO = true,
  SCRIPT = true,
  STYLE = true,
}

local skipNode = {
    HEAD = true,
    NAV = true,
    HEADER = true,
    FOOTER = true
}

local raw = {
    TABLE = 'block',
}

local function handleNode(node, opts)
  local nodeName = node.nodeName
  local parent = node.parentNode
  if skipNode[nodeName] then
    return {}
  end

  if raw[nodeName] == 'block' then
    return builder.html_block(node.outerHTML)
  elseif raw[nodeName] == 'inline' then
    return builder.html_inline(node.outerHTML)
  end

  local child = node.firstChild
  local attributes = node.attributes
  local contents = {}
  local all_text = true
  while child do
    local new = handleNode(child, opts)
    if type(new) == 'table' then
      for _,x in ipairs(new) do
        contents[#contents + 1] = x
      end
    elseif type(new) == 'string' then
      if nodeName ~= 'OL' and nodeName ~= 'UL' then
        contents[#contents + 1] = new
      end
    else
      all_text = false
      contents[#contents + 1] = new
    end
    child = child.nextSibling
  end
  local attrString = ""
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
      attrString = attrString .. ' ' .. attname .. '="' ..
                      attribute.escapedValue .. '"'
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
        blockNode[parent.nodeName] or
        (prevS and (prevS.nodeName == 'BR' or blockNode[prevS.nodeName])) or
        (nextS and blockNode[nextS.nodeName])) then
      if (not prevS or
          prevS.nodeName == 'BR' or
          blockNode[prevS.nodeName]) then
          t = t:gsub('^[ \t\r\n]+','')
      end
      if (not nextS or
          blockNode[nextS.nodeName]) then
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
    if has_text then
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
    if #contents == 1 and
        cmark.node_get_type(contents[1]) == cmark.NODE_CODE then
      local code = cmark.node_get_literal(contents[1])
      local info = nil
      for _,attribute in ipairs(node.firstChild.attributes) do
        if attribute.name == 'class' then
          info = attribute.value:gsub('language%-','')
        end
      end
      return builder.code_block{info = info, code}
    else
      return builder.html_block(node.outerHTML)
    end
  elseif nodeName == 'LI' then
    if all_text then
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
    return builder.code(contents)
  elseif nodeName == 'IMG' then
    return builder.image(contents)
  elseif #contents > 0 then
    if blockNode[nodeName] and not (parent.nodeName == 'P')
        and opts.markdown_in_html then
      table.insert(contents, 1,
                   builder.html_block('<' .. node.localName .. attrString ..
                    '>'))
      if not node.implicitEndTag then
        table.insert(contents,
                   builder.html_block('</' .. node.localName .. '>'))
      end
    else
      table.insert(contents, 1,
                   builder.html_inline('<' .. node.localName .. attrString ..
                    '>'))
      if not node.implicitEndTag then
        table.insert(contents,
                   builder.html_inline('</' .. node.localName .. '>'))
      end
    end
    return contents
  else
    if blockNode[nodeName] then
      return builder.html_block(node.outerHTML)
    else
      return builder.html_inline(node.outerHTML)
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
