local t = require 'helpers'
local util = require 'apple.util'

t.test('mix blends two colors', function()
  t.eq('#808080', util.mix('#FFFFFF', '#000000', 0.5))
  t.eq('#0000FF', util.mix('#FF0000', '#0000FF', 0))
  t.eq('#FF0000', util.mix('#FF0000', '#0000FF', 1))
end)

t.test('has_plugin is true for a loaded module', function()
  t.eq(true, util.has_plugin 'apple.util')
end)

t.test('has_plugin finds a module file on the runtimepath', function()
  -- Forget the module, so only the file lua/apple/util.lua can be found.
  package.loaded['apple.util'] = nil
  t.eq(true, util.has_plugin 'apple.util')
  package.loaded['apple.util'] = util
end)

t.test('has_plugin finds a folder of modules on the runtimepath', function()
  -- lua/apple/ has no init.lua yet, but it has util.lua (lua/apple/*.lua).
  t.eq(true, util.has_plugin 'apple')
end)

t.test('has_plugin is false for an unknown plugin', function()
  t.eq(false, util.has_plugin 'this-plugin-does-not-exist')
end)

t.test('has_plugin accepts a list and returns true when any matches', function()
  t.eq(true, util.has_plugin { 'nope', 'apple.util' })
  t.eq(false, util.has_plugin { 'nope', 'nope2' })
end)

t.test('apply sets highlight groups', function()
  util.apply { AppleTestGroup = { fg = '#FF0000', bold = true } }
  local def = vim.api.nvim_get_hl(0, { name = 'AppleTestGroup' })
  t.eq('#FF0000', t.hex(def.fg))
  t.eq(true, def.bold)
end)
