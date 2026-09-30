local t = require 'helpers'
local palette = require 'apple.palette'
local config = require 'apple.config'

-- Final highlight definition of a group (links resolved).
local function hl(name)
  return vim.api.nvim_get_hl(0, { name = name, link = false })
end

-- Review focus 1: no setup() call, defaults are used.
t.test('colorscheme apple loads without setup()', function()
  config.extend()
  vim.o.background = 'dark'
  local ok, err = pcall(vim.cmd.colorscheme, 'apple')
  t.ok(ok, tostring(err))
  t.eq('apple', vim.g.colors_name)
  t.eq(palette.dark.bg, t.hex(hl('Normal').bg))
end)

for _, mode in ipairs { 'dark', 'light' } do
  local p = palette[mode]

  t.test(mode .. ': loads and sets Normal from the palette', function()
    config.extend()
    vim.o.background = mode
    vim.cmd.colorscheme 'apple'
    t.eq('apple', vim.g.colors_name)
    t.eq(mode, vim.o.background, 'auto mode does not change background')
    t.eq(p.bg, t.hex(hl('Normal').bg), 'Normal bg')
    t.eq(p.fg, t.hex(hl('Normal').fg), 'Normal fg')
  end)

  t.test(mode .. ': Comment is gray and not italic by default', function()
    t.eq(p.comment, t.hex(hl('Comment').fg))
    t.eq(nil, hl('Comment').italic)
  end)

  t.test(mode .. ': syntax groups use Xcode-style colors', function()
    local expected = {
      Statement = p.pink,
      Keyword = p.pink,
      String = p.red,
      Number = p.yellow,
      Constant = p.yellow,
      Function = p.blue,
      Type = p.teal,
      PreProc = p.orange,
      Special = p.purple,
    }
    for group, color in pairs(expected) do
      t.eq(color, t.hex(hl(group).fg), group)
    end
    t.eq(true, hl('Keyword').bold, 'Keyword bold by default')
  end)

  t.test(mode .. ': diagnostics use red, orange, blue, gray, green', function()
    t.eq(p.red, t.hex(hl('DiagnosticError').fg))
    t.eq(p.orange, t.hex(hl('DiagnosticWarn').fg))
    t.eq(p.blue, t.hex(hl('DiagnosticInfo').fg))
    t.eq(p.comment, t.hex(hl('DiagnosticHint').fg))
    t.eq(p.green, t.hex(hl('DiagnosticOk').fg))
    t.eq(true, hl('DiagnosticUnderlineError').undercurl)
  end)

  t.test(mode .. ': search, selection and diff use the palette', function()
    t.eq(p.search, t.hex(hl('Search').bg))
    t.eq(p.cur_search, t.hex(hl('CurSearch').bg))
    t.eq(p.selection, t.hex(hl('Visual').bg))
    t.eq(p.diff_add_bg, t.hex(hl('DiffAdd').bg))
    t.eq(p.diff_delete_bg, t.hex(hl('DiffDelete').bg))
    t.eq(p.diff_text_bg, t.hex(hl('DiffText').bg))
  end)

  t.test(mode .. ': terminal colors are set', function()
    for i = 0, 15 do
      t.eq(p.terminal[i + 1], vim.g['terminal_color_' .. i], 'terminal_color_' .. i)
    end
  end)

  t.test(mode .. ': status line and popup menu use bg_alt', function()
    t.eq(p.bg_alt, t.hex(hl('StatusLine').bg))
    t.eq(p.bg_alt, t.hex(hl('Pmenu').bg))
    t.eq(p.selection, t.hex(hl('PmenuSel').bg))
    t.eq(p.bg_alt, t.hex(hl('NormalFloat').bg))
    t.eq(p.border, t.hex(hl('FloatBorder').fg))
  end)
end

t.test('styles: comments italic and keywords plain when asked', function()
  require('apple').setup { styles = { comments = { italic = true }, keywords = {} } }
  vim.o.background = 'dark'
  vim.cmd.colorscheme 'apple'
  t.eq(true, hl('Comment').italic)
  t.eq(nil, hl('Keyword').bold)
  t.eq(nil, hl('Statement').bold)
  config.extend()
end)

t.test('styles: functions and strings accept styles', function()
  require('apple').setup { styles = { functions = { italic = true }, strings = { bold = true } } }
  vim.cmd.colorscheme 'apple'
  t.eq(true, hl('Function').italic)
  t.eq(true, hl('String').bold)
  config.extend()
end)

t.test('every core group has valid keys and colors', function()
  config.extend()
  local groups = require('apple.groups').get(palette.dark, config.options)
  local valid = { fg = 1, bg = 1, sp = 1, bold = 1, italic = 1, underline = 1, undercurl = 1, strikethrough = 1, reverse = 1, link = 1, blend = 1, nocombine = 1, default = 1 }
  for name, def in pairs(groups) do
    for key, value in pairs(def) do
      t.ok(valid[key], name .. ' has unknown key ' .. key)
      if key == 'fg' or key == 'bg' or key == 'sp' then t.ok(value == 'NONE' or value:match '^#%x%x%x%x%x%x$', name .. '.' .. key .. ' = ' .. tostring(value)) end
    end
  end
end)
