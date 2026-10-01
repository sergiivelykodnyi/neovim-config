local t = require 'helpers'
local palette = require 'apple.palette'
local config = require 'apple.config'

-- Final highlight definition of a group (links resolved).
local function hl(name) return vim.api.nvim_get_hl(0, { name = name, link = false }) end

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
  local valid = {
    fg = 1,
    bg = 1,
    sp = 1,
    bold = 1,
    italic = 1,
    underline = 1,
    undercurl = 1,
    strikethrough = 1,
    reverse = 1,
    link = 1,
    blend = 1,
    nocombine = 1,
    default = 1,
  }
  for name, def in pairs(groups) do
    for key, value in pairs(def) do
      t.ok(valid[key], name .. ' has unknown key ' .. key)
      if key == 'fg' or key == 'bg' or key == 'sp' then
        t.ok(value == 'NONE' or value:match '^#%x%x%x%x%x%x$', name .. '.' .. key .. ' = ' .. tostring(value))
      end
    end
  end
end)

for _, mode in ipairs { 'dark', 'light' } do
  local p = palette[mode]

  t.test(mode .. ': treesitter captures follow the Xcode colors', function()
    config.extend()
    vim.o.background = mode
    vim.cmd.colorscheme 'apple'
    t.eq(p.fg, t.hex(hl('@variable').fg), '@variable')
    t.eq(p.purple, t.hex(hl('@variable.builtin').fg), '@variable.builtin')
    t.eq(p.pink, t.hex(hl('@keyword').fg), '@keyword')
    t.eq(true, hl('@keyword').bold, '@keyword bold')
    t.eq(p.pink, t.hex(hl('@keyword.return').fg), '@keyword.return')
    t.eq(p.blue, t.hex(hl('@function').fg), '@function')
    t.eq(p.blue, t.hex(hl('@function.method').fg), '@function.method')
    t.eq(p.teal, t.hex(hl('@type').fg), '@type')
    t.eq(p.red, t.hex(hl('@string').fg), '@string')
    t.eq(p.purple, t.hex(hl('@string.escape').fg), '@string.escape')
    t.eq(p.yellow, t.hex(hl('@number').fg), '@number')
    t.eq(p.orange, t.hex(hl('@keyword.import').fg), '@keyword.import')
    t.eq(p.comment, t.hex(hl('@comment').fg), '@comment')
    t.eq(p.fg, t.hex(hl('@punctuation.delimiter').fg), '@punctuation.delimiter')
  end)

  t.test(mode .. ': markup captures for markdown and help', function()
    t.eq(true, hl('@markup.strong').bold)
    t.eq(true, hl('@markup.italic').italic)
    t.eq(p.blue, t.hex(hl('@markup.heading').fg))
    t.eq(p.blue, t.hex(hl('@markup.link.url').fg))
    t.eq(true, hl('@markup.link.url').underline)
    t.eq(p.green, t.hex(hl('@diff.plus').fg))
    t.eq(p.red, t.hex(hl('@diff.minus').fg))
  end)

  t.test(mode .. ': LSP semantic tokens and references', function()
    t.eq(p.teal, t.hex(hl('@lsp.type.class').fg), '@lsp.type.class')
    t.eq(p.fg, t.hex(hl('@lsp.type.variable').fg), '@lsp.type.variable')
    t.eq(p.blue, t.hex(hl('@lsp.type.function').fg), '@lsp.type.function')
    t.eq(true, hl('@lsp.mod.deprecated').strikethrough, '@lsp.mod.deprecated')
    t.eq(p.bg_alt, t.hex(hl('LspReferenceText').bg), 'LspReferenceText')
    t.eq(p.comment, t.hex(hl('LspInlayHint').fg), 'LspInlayHint')
    t.eq(p.bg_alt, t.hex(hl('LspInlayHint').bg), 'LspInlayHint bg')
    t.eq(true, hl('LspSignatureActiveParameter').bold)
  end)
end

t.test('styles apply to treesitter captures too', function()
  require('apple').setup { styles = { comments = { italic = true }, keywords = {}, functions = { italic = true }, strings = { bold = true } } }
  vim.cmd.colorscheme 'apple'
  t.eq(true, hl('@comment').italic)
  t.eq(nil, hl('@keyword').bold)
  t.eq(nil, hl('@keyword.function').bold)
  t.eq(true, hl('@function').italic)
  t.eq(true, hl('@string').bold)
  config.extend()
end)

t.test('flavor = light forces background and palette', function()
  require('apple').setup { flavor = 'light' }
  vim.o.background = 'dark'
  vim.cmd.colorscheme 'apple'
  -- 'background' is corrected on the next event-loop tick.
  vim.wait(200, function() return vim.o.background == 'light' end)
  t.eq('light', vim.o.background)
  t.eq(palette.light.bg, t.hex(hl('Normal').bg))
  t.eq('apple', vim.g.colors_name)
  config.extend()
end)

t.test('flavor = dark wins when the terminal switches background', function()
  require('apple').setup { flavor = 'dark' }
  vim.o.background = 'dark'
  vim.cmd.colorscheme 'apple'
  -- Neovim reloads the colorscheme on this change; the theme sets it back
  -- on the next event-loop tick.
  vim.o.background = 'light'
  vim.wait(200, function() return vim.o.background == 'dark' end)
  t.eq('dark', vim.o.background)
  t.eq(palette.dark.bg, t.hex(hl('Normal').bg))
  config.extend()
end)

-- Review focus 3: auto mode follows a background change at runtime.
t.test('auto flavor follows background changes after load', function()
  config.extend()
  vim.o.background = 'dark'
  vim.cmd.colorscheme 'apple'
  vim.o.background = 'light'
  t.eq('apple', vim.g.colors_name)
  t.eq(palette.light.bg, t.hex(hl('Normal').bg))
  vim.o.background = 'dark'
  t.eq(palette.dark.bg, t.hex(hl('Normal').bg))
end)

t.test('on_highlights can change and add groups', function()
  require('apple').setup {
    on_highlights = function(groups, p)
      groups.Comment = { fg = p.blue }
      groups.AppleCustom = { fg = p.green, bold = true }
    end,
  }
  vim.cmd.colorscheme 'apple'
  t.eq(palette.dark.blue, t.hex(hl('Comment').fg))
  t.eq(palette.dark.green, t.hex(hl('AppleCustom').fg))
  t.eq(true, hl('AppleCustom').bold)
  config.extend()
end)

-- Review focus 4: an error in on_highlights must not block the next load.
t.test('a failing on_highlights does not break the next load', function()
  require('apple').setup {
    on_highlights = function() error 'boom' end,
  }
  local ok = pcall(vim.cmd.colorscheme, 'apple')
  t.eq(false, ok, 'error is reported')
  config.extend()
  local ok2, err = pcall(vim.cmd.colorscheme, 'apple')
  t.ok(ok2, tostring(err))
  t.eq(palette.dark.bg, t.hex(hl('Normal').bg))
end)

t.test('switching from a forced flavor to auto in the same tick does not change background', function()
  vim.o.background = 'dark'
  require('apple').setup { flavor = 'light' }
  vim.cmd.colorscheme 'apple'
  -- The user changes their mind before the scheduled background fix runs.
  require('apple').setup {}
  vim.cmd.colorscheme 'apple'
  vim.wait(200, function() return false end)
  t.eq('dark', vim.o.background, 'auto mode must not touch background')
  t.eq(palette.dark.bg, t.hex(hl('Normal').bg))
  config.extend()
end)

t.test('contrast = increased loads the increased contrast palette', function()
  require('apple').setup { contrast = 'increased' }
  vim.o.background = 'dark'
  vim.cmd.colorscheme 'apple'
  local p = palette.dark_contrast
  t.eq(p.bg, t.hex(hl('Normal').bg), 'Normal bg')
  t.eq(p.red, t.hex(hl('String').fg), 'String')
  t.eq(p.comment, t.hex(hl('Comment').fg), 'Comment')
  t.eq(p.terminal[2], vim.g.terminal_color_1, 'terminal_color_1')
  config.extend()
end)

t.test('contrast = increased works with a forced light flavor', function()
  require('apple').setup { flavor = 'light', contrast = 'increased' }
  vim.o.background = 'light'
  vim.cmd.colorscheme 'apple'
  t.eq(palette.light_contrast.bg, t.hex(hl('Normal').bg))
  config.extend()
end)

-- Review focus 1: a wrong value means default colors, not an error.
t.test('an unknown contrast value loads the default colors', function()
  vim.o.background = 'dark'
  for _, value in ipairs { 'high', '', true, 1 } do
    require('apple').setup { contrast = value }
    local ok, err = pcall(vim.cmd.colorscheme, 'apple')
    t.ok(ok, tostring(err))
    t.eq(palette.dark.bg, t.hex(hl('Normal').bg), 'contrast = ' .. vim.inspect(value))
  end
  config.extend()
end)

-- Review focus 2: the option can change at runtime, in both directions.
t.test('changing contrast and reloading switches the palette both ways', function()
  config.extend()
  vim.o.background = 'dark'
  vim.cmd.colorscheme 'apple'
  t.eq(palette.dark.bg, t.hex(hl('Normal').bg), 'default first')
  require('apple').setup { contrast = 'increased' }
  vim.cmd.colorscheme 'apple'
  t.eq(palette.dark_contrast.bg, t.hex(hl('Normal').bg), 'then increased')
  require('apple').setup {}
  vim.cmd.colorscheme 'apple'
  t.eq(palette.dark.bg, t.hex(hl('Normal').bg), 'then default again')
end)

-- Review focus 3: auto mode keeps the contrast when the terminal switches.
t.test('auto flavor keeps increased contrast when background changes', function()
  require('apple').setup { contrast = 'increased' }
  vim.o.background = 'dark'
  vim.cmd.colorscheme 'apple'
  vim.o.background = 'light'
  t.eq(palette.light_contrast.bg, t.hex(hl('Normal').bg), 'light')
  vim.o.background = 'dark'
  t.eq(palette.dark_contrast.bg, t.hex(hl('Normal').bg), 'dark')
  config.extend()
end)

-- Review focus 4: plugins that load after :colorscheme get the same palette.
t.test('integrations added after load use the increased contrast palette', function()
  local apple = require 'apple'
  apple.setup { contrast = 'increased', integrations = { telescope = false } }
  vim.o.background = 'dark'
  vim.cmd 'highlight clear'
  vim.cmd.colorscheme 'apple'
  apple.setup { contrast = 'increased', integrations = { telescope = true } }
  t.eq(true, apple.apply_new_integrations())
  t.eq(palette.dark_contrast.bg_alt, t.hex(hl('TelescopeNormal').bg))
  config.extend()
end)

t.test('on_highlights gets the increased contrast palette', function()
  local seen
  require('apple').setup {
    contrast = 'increased',
    on_highlights = function(_, p) seen = p end,
  }
  vim.o.background = 'dark'
  vim.cmd.colorscheme 'apple'
  t.ok(seen == palette.dark_contrast, 'palette passed to on_highlights')
  config.extend()
  vim.cmd.colorscheme 'apple'
end)
