local t = require 'helpers'
local palette = require 'apple.palette'
local config = require 'apple.config'
local groups = require 'apple.groups'

local function hl(name)
  return vim.api.nvim_get_hl(0, { name = name, link = false })
end

local valid = { fg = 1, bg = 1, sp = 1, bold = 1, italic = 1, underline = 1, undercurl = 1, strikethrough = 1, reverse = 1, link = 1, blend = 1, nocombine = 1, default = 1 }

t.test('integration list has the expected names', function()
  t.ok(vim.tbl_contains(groups.integrations, 'telescope'), 'telescope is listed')
end)

-- Generic checks for every integration file.
for _, name in ipairs(groups.integrations) do
  local mod = require('apple.groups.' .. name)

  t.test(name .. ': has detect and get', function()
    t.ok(type(mod.detect) == 'string' or type(mod.detect) == 'table', 'detect')
    t.eq('function', type(mod.get))
  end)

  for _, mode in ipairs { 'dark', 'light' } do
    t.test(name .. ' (' .. mode .. '): returns valid highlight definitions', function()
      local defs = mod.get(palette[mode], config.defaults)
      t.ok(next(defs) ~= nil, 'not empty')
      for group, def in pairs(defs) do
        t.eq('table', type(def), group)
        for key, value in pairs(def) do
          t.ok(valid[key], group .. ' has unknown key ' .. key)
          if key == 'fg' or key == 'bg' or key == 'sp' then t.ok(value == 'NONE' or value:match '^#%x%x%x%x%x%x$', group .. '.' .. key .. ' = ' .. tostring(value)) end
        end
      end
    end)
  end

  t.test(name .. ': is off when the plugin is missing (nvim --clean)', function()
    t.eq(false, groups.enabled(name, config.defaults))
  end)

  t.test(name .. ': can be forced on', function()
    t.eq(true, groups.enabled(name, { integrations = { [name] = true } }))
  end)
end

t.test('forced integration groups are applied by :colorscheme', function()
  require('apple').setup { integrations = { telescope = true } }
  vim.o.background = 'dark'
  vim.cmd.colorscheme 'apple'
  t.eq(palette.dark.bg_alt, t.hex(hl('TelescopeNormal').bg))
  config.extend()
end)

t.test('integration set to false is not applied', function()
  require('apple').setup { integrations = { telescope = false } }
  vim.cmd 'highlight clear'
  vim.cmd.colorscheme 'apple'
  local def = vim.api.nvim_get_hl(0, { name = 'TelescopeNormal' })
  t.eq(true, vim.tbl_isempty(def), 'TelescopeNormal is not defined')
  config.extend()
end)

t.test('a loaded module turns the integration on', function()
  package.loaded['telescope'] = {}
  t.eq(true, groups.enabled('telescope', config.defaults))
  package.loaded['telescope'] = nil
end)

-- Review focus 5: unknown integration names are ignored.
t.test('unknown integration names are ignored', function()
  require('apple').setup { integrations = { not_a_real_plugin = true } }
  local ok, err = pcall(vim.cmd.colorscheme, 'apple')
  t.ok(ok, tostring(err))
  config.extend()
end)

t.test('blink, gitsigns, which_key, todo_comments are listed', function()
  for _, name in ipairs { 'blink', 'gitsigns', 'which_key', 'todo_comments' } do
    t.ok(vim.tbl_contains(groups.integrations, name), name)
  end
end)

t.test('blink: menu uses bg_alt, selection uses the selection color', function()
  local defs = require('apple.groups.blink').get(palette.dark, config.defaults)
  t.eq(palette.dark.bg_alt, defs.BlinkCmpMenu.bg)
  t.eq(palette.dark.selection, defs.BlinkCmpMenuSelection.bg)
  t.eq(palette.dark.blue, defs.BlinkCmpLabelMatch.fg)
  t.eq('blink.cmp', require('apple.groups.blink').detect)
end)

t.test('gitsigns: add/change/delete use green/blue/red', function()
  local defs = require('apple.groups.gitsigns').get(palette.light, config.defaults)
  t.eq(palette.light.green, defs.GitSignsAdd.fg)
  t.eq(palette.light.blue, defs.GitSignsChange.fg)
  t.eq(palette.light.red, defs.GitSignsDelete.fg)
  t.eq(palette.light.diff_add_bg, defs.GitSignsAddLn.bg)
end)

t.test('which_key: key is blue, group is teal', function()
  local defs = require('apple.groups.which_key').get(palette.dark, config.defaults)
  t.eq(palette.dark.blue, defs.WhichKey.fg)
  t.eq(palette.dark.teal, defs.WhichKeyGroup.fg)
  t.eq('which-key', require('apple.groups.which_key').detect)
end)

t.test('todo_comments: keyword colors follow diagnostics', function()
  local defs = require('apple.groups.todo_comments').get(palette.dark, config.defaults)
  t.eq(palette.dark.red, defs.TodoFgFIX.fg)
  t.eq(palette.dark.blue, defs.TodoFgTODO.fg)
  t.eq(palette.dark.orange, defs.TodoFgWARN.fg)
  t.eq(palette.dark.bg, defs.TodoBgTODO.fg)
  t.eq(palette.dark.blue, defs.TodoBgTODO.bg)
  t.eq('todo-comments', require('apple.groups.todo_comments').detect)
end)

t.test('mini, fidget, mason are listed', function()
  for _, name in ipairs { 'mini', 'fidget', 'mason' } do
    t.ok(vim.tbl_contains(groups.integrations, name), name)
  end
end)

for _, mode in ipairs { 'dark', 'light' } do
  local p = palette[mode]
  t.test('mini (' .. mode .. '): statusline mode blocks use one Apple color and are readable', function()
    local defs = require('apple.groups.mini').get(p, config.defaults)
    local expected = {
      MiniStatuslineModeNormal = p.blue,
      MiniStatuslineModeInsert = p.green,
      MiniStatuslineModeVisual = p.purple,
      MiniStatuslineModeReplace = p.red,
      MiniStatuslineModeCommand = p.orange,
      MiniStatuslineModeOther = p.teal,
    }
    for group, color in pairs(expected) do
      t.eq(color, defs[group].bg, group .. ' bg')
      t.eq(true, defs[group].bold, group .. ' bold')
      -- The mode name is bold, so 3.0 (WCAG for bold text) is enough.
      t.min_contrast(defs[group].fg, defs[group].bg, 3.0, group)
    end
    t.eq(p.bg_alt, defs.MiniStatuslineFilename.bg)
    t.eq(p.border, defs.MiniStatuslineDevinfo.bg)
    t.min_contrast(defs.MiniStatuslineDevinfo.fg, p.border, 4.5, 'Devinfo')
    t.min_contrast(defs.MiniStatuslineInactive.fg, defs.MiniStatuslineInactive.bg, 3.0, 'Inactive')
  end)
end

t.test('mini: icon colors map to the palette', function()
  local defs = require('apple.groups.mini').get(palette.dark, config.defaults)
  t.eq(palette.dark.blue, defs.MiniIconsBlue.fg)
  t.eq(palette.dark.teal, defs.MiniIconsCyan.fg)
  t.eq(palette.dark.comment, defs.MiniIconsGrey.fg)
  t.eq('mini', require('apple.groups.mini').detect)
end)

t.test('fidget: title is blue, tasks are gray', function()
  local defs = require('apple.groups.fidget').get(palette.dark, config.defaults)
  t.eq(palette.dark.blue, defs.FidgetTitle.fg)
  t.eq(palette.dark.comment, defs.FidgetTask.fg)
end)

t.test('mason: header is a blue block with readable text', function()
  local defs = require('apple.groups.mason').get(palette.light, config.defaults)
  t.eq(palette.light.blue, defs.MasonHeader.bg)
  t.min_contrast(defs.MasonHeader.fg, defs.MasonHeader.bg, 3.0, 'MasonHeader')
  t.eq(palette.light.comment, defs.MasonMuted.fg)
end)

t.test('the integration list matches the spec', function()
  t.eq({ 'telescope', 'blink', 'gitsigns', 'which_key', 'todo_comments', 'mini', 'fidget', 'mason', 'indent_blankline', 'neo_tree', 'dap' }, groups.integrations)
end)

t.test('indent_blankline: guides use the border gray, scope is stronger', function()
  local defs = require('apple.groups.indent_blankline').get(palette.dark, config.defaults)
  t.eq(palette.dark.border, defs.IblIndent.fg)
  t.eq(palette.dark.comment, defs.IblScope.fg)
  t.eq('ibl', require('apple.groups.indent_blankline').detect)
end)

t.test('neo_tree: window uses bg_alt, folders are blue, git states colored', function()
  local defs = require('apple.groups.neo_tree').get(palette.light, config.defaults)
  t.eq(palette.light.bg_alt, defs.NeoTreeNormal.bg)
  t.eq(palette.light.blue, defs.NeoTreeDirectoryName.fg)
  t.eq(palette.light.green, defs.NeoTreeGitAdded.fg)
  t.eq(palette.light.red, defs.NeoTreeGitDeleted.fg)
  t.eq('neo-tree', require('apple.groups.neo_tree').detect)
end)

t.test('dap: breakpoint red, stopped green, dapui detected too', function()
  local defs = require('apple.groups.dap').get(palette.dark, config.defaults)
  t.eq(palette.dark.red, defs.DapBreakpoint.fg)
  t.eq(palette.dark.green, defs.DapStopped.fg)
  t.eq(palette.dark.diff_add_bg, defs.DapStoppedLine.bg)
  t.eq({ 'dap', 'dapui' }, require('apple.groups.dap').detect)
end)
