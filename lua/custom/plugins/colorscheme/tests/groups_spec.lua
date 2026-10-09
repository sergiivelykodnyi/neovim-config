local t = require 'helpers'
local palette = require 'custom.plugins.colorscheme.palette'

local core = { 'editor', 'syntax', 'treesitter', 'lsp' }

local function is_color(value) return value == 'NONE' or (type(value) == 'string' and value:match '^#%x%x%x%x%x%x$' ~= nil) end

-- Every core file returns groups whose colors come from the palette.
-- The strict palette errors on an unknown key, so a typo like p.purpel fails here.
for _, name in ipairs(core) do
  t.test('groups/' .. name .. ' uses only palette colors', function()
    local groups = require('custom.plugins.colorscheme.groups.' .. name).get(t.strict(palette))
    t.ok(type(groups) == 'table' and next(groups) ~= nil, 'returns a non-empty table')
    for group, def in pairs(groups) do
      t.ok(type(def) == 'table', group .. ' is a table')
      for _, key in ipairs { 'fg', 'bg', 'sp' } do
        if def[key] ~= nil then t.ok(is_color(def[key]), ('%s.%s = %s'):format(group, key, tostring(def[key]))) end
      end
      if def.link then t.ok(type(def.link) == 'string', group .. '.link is a string') end
    end
  end)

  t.test('groups/' .. name .. ' has no bold and no italic', function()
    local groups = require('custom.plugins.colorscheme.groups.' .. name).get(palette)
    for group, def in pairs(groups) do
      t.ok(not def.bold, group .. ' is not bold')
      t.ok(not def.italic, group .. ' is not italic')
    end
  end)
end

t.test('editor groups use the VSCode values', function()
  local g = require('custom.plugins.colorscheme.groups.editor').get(palette)
  t.eq({ fg = palette.fg, bg = palette.bg }, g.Normal, 'Normal')
  t.eq({ bg = palette.bg_line }, g.CursorLine, 'CursorLine')
  t.eq({ fg = palette.line_nr }, g.LineNr, 'LineNr')
  t.eq({ bg = palette.selection }, g.Visual, 'Visual')
  t.eq({ bg = palette.search }, g.CurSearch, 'CurSearch')
  t.eq({ bg = palette.search_other }, g.Search, 'Search')
  t.eq({ fg = palette.fg, bg = palette.bg_float }, g.NormalFloat, 'NormalFloat')
  t.eq({ fg = palette.border, bg = palette.bg_float }, g.FloatBorder, 'FloatBorder')
  t.eq({ fg = palette.status_fg, bg = palette.bg }, g.StatusLine, 'StatusLine')
end)

t.test('syntax groups cover files without a tree-sitter parser', function()
  local g = require('custom.plugins.colorscheme.groups.syntax').get(palette)
  local names = { 'Comment', 'String', 'Number', 'Keyword', 'Function', 'Type', 'Constant', 'Identifier' }
  vim.list_extend(names, { 'Operator', 'Statement', 'PreProc', 'Special', 'Todo', 'Error' })
  for _, name in ipairs(names) do
    t.ok(g[name], name .. ' is defined')
  end
  t.eq({ fg = palette.comment }, g.Comment, 'Comment')
  t.eq({ fg = palette.green }, g.String, 'String')
  t.eq({ fg = palette.purple }, g.Keyword, 'Keyword')
end)

t.test('treesitter captures follow the One Dark mapping', function()
  local g = require('custom.plugins.colorscheme.groups.treesitter').get(palette)
  t.eq({ fg = palette.red }, g['@variable'], '@variable')
  t.eq({ fg = palette.yellow }, g['@variable.builtin'], '@variable.builtin')
  t.eq({ fg = palette.orange }, g['@constant'], '@constant')
  t.eq({ fg = palette.green }, g['@string'], '@string')
  t.eq({ fg = palette.cyan }, g['@string.escape'], '@string.escape')
  t.eq({ fg = palette.blue }, g['@function'], '@function')
  t.eq({ fg = palette.cyan }, g['@function.builtin'], '@function.builtin')
  t.eq({ fg = palette.purple }, g['@keyword'], '@keyword')
  t.eq({ fg = palette.purple }, g['@keyword.operator'], '@keyword.operator')
  t.eq({ fg = palette.cyan }, g['@operator'], '@operator')
  t.eq({ fg = palette.orange }, g['@punctuation.bracket'], '@punctuation.bracket')
  t.eq({ fg = palette.cyan }, g['@string.regexp'], '@string.regexp')
  t.eq({ fg = palette.yellow }, g['@type'], '@type')
  t.eq({ fg = palette.red }, g['@tag'], '@tag')
  t.eq({ fg = palette.orange }, g['@tag.attribute'], '@tag.attribute')
  t.eq({ fg = palette.red }, g['@markup.heading'], '@markup.heading')
  t.eq({ fg = palette.purple, underline = true }, g['@markup.link.url'], '@markup.link.url')
  t.eq({ fg = palette.cyan }, g['@boolean.json'], '@boolean.json')
  t.eq({ fg = palette.fg }, g['@property.css'], '@property.css')
  t.eq({ fg = palette.red }, g['@type.unit.css'], '@type.unit.css')
  t.eq({ fg = palette.red }, g['@type.unit.scss'], '@type.unit.scss')
  t.eq({ fg = palette.orange }, g['@constant.color.scss'], '@constant.color.scss')
  t.eq({ fg = palette.orange }, g['@constant.value.scss'], '@constant.value.scss')
  t.eq({ fg = palette.cyan }, g['@function.css'], '@function.css')
  t.eq({ fg = palette.fg }, g['@operator.lua'], '@operator.lua')
  t.eq({ fg = palette.cyan }, g['@keyword.operator.lua'], '@keyword.operator.lua')
  t.eq({ fg = palette.red }, g['@constant.lua'], '@constant.lua')
  t.eq({ fg = palette.yellow }, g['@constant.typescript'], '@constant.typescript')
  t.eq({ fg = palette.dim }, g['@punctuation.special.markdown'], '@punctuation.special.markdown')
end)

t.test('the CSS query extension adds the captures the theme uses', function()
  local script = debug.getinfo(1, 'S').source:sub(2)
  local root = vim.fn.fnamemodify(script, ':p:h:h:h:h:h:h')
  local lines = vim.fn.readfile(root .. '/after/queries/css/highlights.scm')
  t.eq(';; extends', lines[1], 'first line')
  local text = table.concat(lines, '\n')
  for _, capture in ipairs { '@type.unit', '@constant.color', '@constant.value' } do
    t.ok(text:find(capture, 1, true), capture .. ' is in the query')
  end
end)

t.test('lsp tokens and diagnostics follow the One Dark mapping', function()
  local g = require('custom.plugins.colorscheme.groups.lsp').get(palette)
  t.eq({}, g['@lsp.type.variable'], 'variable keeps the tree-sitter color')
  t.eq(nil, g['@lsp.typemod.variable.readonly'], 'readonly is not overridden')
  t.eq({ fg = palette.blue }, g['@lsp.type.member'], 'member')
  t.eq({ fg = palette.yellow }, g['@lsp.typemod.variable.global'], 'global')
  t.eq({ fg = palette.yellow }, g['@lsp.typemod.variable.defaultLibrary'], 'defaultLibrary')
  t.eq({ fg = palette.cyan }, g['@lsp.typemod.function.defaultLibrary'], 'function.defaultLibrary')
  t.eq({ fg = palette.cyan }, g['@lsp.type.enumMember'], 'enumMember')
  t.eq({ fg = palette.diag_error }, g.DiagnosticError, 'DiagnosticError')
  t.eq({ sp = palette.diag_warn, undercurl = true }, g.DiagnosticUnderlineWarn, 'DiagnosticUnderlineWarn')
end)
