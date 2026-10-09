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
  t.eq({ fg = palette.fg }, g['@punctuation.bracket'], '@punctuation.bracket')
  t.eq({ fg = palette.yellow }, g['@type'], '@type')
  t.eq({ fg = palette.red }, g['@tag'], '@tag')
  t.eq({ fg = palette.orange }, g['@tag.attribute'], '@tag.attribute')
  t.eq({ fg = palette.red }, g['@markup.heading'], '@markup.heading')
  t.eq({ fg = palette.purple, underline = true }, g['@markup.link.url'], '@markup.link.url')
  t.eq({ fg = palette.cyan }, g['@boolean.json'], '@boolean.json')
  t.eq({ fg = palette.fg }, g['@property.css'], '@property.css')
end)

t.test('lsp tokens and diagnostics follow the One Dark mapping', function()
  local g = require('custom.plugins.colorscheme.groups.lsp').get(palette)
  t.eq({ fg = palette.yellow }, g['@lsp.typemod.variable.readonly'], 'readonly')
  t.eq({ fg = palette.yellow }, g['@lsp.typemod.variable.defaultLibrary'], 'defaultLibrary')
  t.eq({ fg = palette.cyan }, g['@lsp.typemod.function.defaultLibrary'], 'function.defaultLibrary')
  t.eq({ fg = palette.cyan }, g['@lsp.type.enumMember'], 'enumMember')
  t.eq({ fg = palette.diag_error }, g.DiagnosticError, 'DiagnosticError')
  t.eq({ sp = palette.diag_warn, undercurl = true }, g.DiagnosticUnderlineWarn, 'DiagnosticUnderlineWarn')
end)
