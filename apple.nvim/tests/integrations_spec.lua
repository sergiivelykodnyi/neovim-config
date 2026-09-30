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
