local t = require 'helpers'
local util = require 'custom.plugins.colorscheme.util'

t.test('has_plugin finds a module on the runtimepath', function()
  -- The colorscheme module itself is on the runtimepath (tests/run.lua adds the repo root).
  t.ok(util.has_plugin 'custom.plugins.colorscheme', 'own module')
  t.ok(util.has_plugin { 'no.such.plugin', 'custom.plugins.colorscheme.palette' }, 'one of a list')
end)

t.test('has_plugin is false for a missing module', function()
  t.ok(not util.has_plugin 'no.such.plugin', 'missing')
  t.ok(not util.has_plugin { 'no.such.plugin', 'another.missing' }, 'missing list')
end)

t.test('has_plugin is true for a loaded module without files', function()
  package.loaded['fake.loaded.module'] = {}
  t.ok(util.has_plugin 'fake.loaded.module', 'loaded')
  package.loaded['fake.loaded.module'] = nil
end)

t.test('apply sets highlight groups', function()
  util.apply { OnedarkTestGroup = { fg = '#e06c75', bg = '#16191d' } }
  local hl = vim.api.nvim_get_hl(0, { name = 'OnedarkTestGroup' })
  t.eq('#e06c75', t.hex(hl.fg), 'fg')
  t.eq('#16191d', t.hex(hl.bg), 'bg')
end)
