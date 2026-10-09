local t = require 'helpers'
local palette = require 'custom.plugins.colorscheme.palette'

local function fresh()
  t.unload 'custom.plugins.colorscheme'
  -- The group exists only after the first load, so ignore the error.
  pcall(vim.api.nvim_clear_autocmds, { group = 'onedark-startup' })
  return require 'custom.plugins.colorscheme'
end

-- Number of autocmds in the startup group; 0 when the group does not exist.
local function startup_autocmds()
  local ok, list = pcall(vim.api.nvim_get_autocmds, { group = 'onedark-startup' })
  return ok and #list or 0
end

t.test('requiring the module applies the theme', function()
  fresh()
  t.eq('onedark', vim.g.colors_name, 'colors_name')
  local normal = vim.api.nvim_get_hl(0, { name = 'Normal' })
  t.eq(palette.fg, t.hex(normal.fg), 'Normal fg')
  t.eq(palette.bg, t.hex(normal.bg), 'Normal bg')
  local keyword = vim.api.nvim_get_hl(0, { name = '@keyword' })
  t.eq(palette.purple, t.hex(keyword.fg), '@keyword fg')
end)

t.test('terminal colors are set', function()
  fresh()
  for i = 0, 15 do
    t.eq(palette.terminal[i + 1], vim.g['terminal_color_' .. i], 'terminal_color_' .. i)
  end
end)

t.test('requiring the module twice works and keeps one autocmd group', function()
  fresh()
  t.unload 'custom.plugins.colorscheme'
  require 'custom.plugins.colorscheme'
  t.eq('onedark', vim.g.colors_name, 'colors_name')
  local count = startup_autocmds()
  t.ok(count <= 1, 'at most one VimEnter autocmd, got ' .. count)
end)

t.test('a plugin added later gets its groups from apply_new_integrations', function()
  local M = fresh()
  -- Before: telescope is not on the runtimepath, so its groups are not set.
  t.eq(nil, vim.api.nvim_get_hl(0, { name = 'TelescopeSelection' }).bg, 'no telescope group yet')

  -- Simulate a plugin that appears after the theme ran.
  local dir = vim.fn.tempname()
  vim.fn.mkdir(dir .. '/lua/telescope', 'p')
  vim.fn.writefile({ 'return {}' }, dir .. '/lua/telescope/init.lua')
  vim.opt.runtimepath:append(dir)

  t.ok(M.apply_new_integrations(), 'reports that something was added')
  t.eq(palette.bg_select, t.hex(vim.api.nvim_get_hl(0, { name = 'TelescopeSelection' }).bg), 'TelescopeSelection bg')
  t.ok(not M.apply_new_integrations(), 'second call adds nothing')

  vim.opt.runtimepath:remove(dir)
  vim.fn.delete(dir, 'rf')
end)

t.test('a broken integration does not stop the theme', function()
  local M = fresh()
  local dir = vim.fn.tempname()
  -- A fake plugin "brokenplug" and a broken group file for it.
  vim.fn.mkdir(dir .. '/lua/brokenplug', 'p')
  vim.fn.writefile({ 'return {}' }, dir .. '/lua/brokenplug/init.lua')
  vim.fn.mkdir(dir .. '/lua/custom/plugins/colorscheme/groups', 'p')
  local broken = "return { detect = 'brokenplug', get = function() error 'boom' end }"
  vim.fn.writefile({ broken }, dir .. '/lua/custom/plugins/colorscheme/groups/brokenplug.lua')
  vim.opt.runtimepath:append(dir)
  -- Only the broken one, so the count below is exact.
  local integrations = M.integrations
  M.integrations = { 'brokenplug' }

  local messages = {}
  local notify = vim.notify
  vim.notify = function(msg, level) messages[#messages + 1] = { msg = msg, level = level } end
  local ok = pcall(M.load)
  M.apply_new_integrations()
  vim.notify = notify

  t.ok(ok, 'load() did not raise')
  t.eq('onedark', vim.g.colors_name, 'theme still applied')
  t.eq(1, #messages, 'error reported once')
  t.ok(messages[1].msg:find 'brokenplug', 'message names the integration')
  t.eq(vim.log.levels.ERROR, messages[1].level, 'error level')

  M.integrations = integrations
  vim.opt.runtimepath:remove(dir)
  vim.fn.delete(dir, 'rf')
  t.unload 'custom.plugins.colorscheme.groups.brokenplug'
end)
