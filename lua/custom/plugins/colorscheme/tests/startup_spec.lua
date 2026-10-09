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
  -- Under -l, VimEnter has already fired, so the loader must not add an autocmd.
  -- Before VimEnter (a real startup) it adds exactly one. Both loads agree.
  t.eq(vim.v.vim_did_enter == 1 and 0 or 1, startup_autocmds(), 'startup autocmds')
end)

t.test('a plugin added after the theme during startup gets its groups at VimEnter', function()
  -- A real startup in a child Neovim: the theme loads first, then a fake
  -- telescope appears on the runtimepath, as kickstart's init.lua does.
  local script = debug.getinfo(1, 'S').source:sub(2)
  local root = vim.fn.fnamemodify(script, ':p:h:h:h:h:h:h')
  local dir = vim.fn.tempname()
  vim.fn.mkdir(dir .. '/plugin/lua/telescope', 'p')
  vim.fn.writefile({ 'return {}' }, dir .. '/plugin/lua/telescope/init.lua')
  local init = dir .. '/init.lua'
  vim.fn.writefile({
    ('vim.opt.runtimepath:prepend(%q)'):format(root),
    "require 'custom.plugins.colorscheme'",
    ('vim.opt.runtimepath:append(%q)'):format(dir .. '/plugin'),
    'vim.schedule(function()',
    "  local hl = vim.api.nvim_get_hl(0, { name = 'TelescopeSelection' })",
    "  local ok, list = pcall(vim.api.nvim_get_autocmds, { group = 'onedark-startup' })",
    "  io.stdout:write(('%s %d\\n'):format(hl.bg and ('#%06x'):format(hl.bg) or 'nil', ok and #list or -1))",
    "  vim.cmd 'qa!'",
    'end)',
  }, init)
  local result = vim.system({ 'nvim', '--clean', '--headless', '-u', init }, { text = true }):wait()
  vim.fn.delete(dir, 'rf')
  t.eq(0, result.code, 'child exit code: ' .. (result.stderr or ''))
  t.eq(palette.bg_select .. ' 0', vim.trim(result.stdout), 'TelescopeSelection bg and no autocmd left after VimEnter')
end)

t.test(':colorscheme onedark applies the theme again', function()
  fresh()
  vim.cmd 'highlight clear'
  vim.cmd.colorscheme 'onedark'
  t.eq('onedark', vim.g.colors_name, 'colors_name')
  t.eq(palette.bg, t.hex(vim.api.nvim_get_hl(0, { name = 'Normal' }).bg), 'Normal bg')
end)

t.test("a 'background' change keeps the theme", function()
  fresh()
  -- Neovim re-runs colors/<colors_name> when 'background' changes.
  vim.o.background = 'light'
  t.eq(palette.bg, t.hex(vim.api.nvim_get_hl(0, { name = 'Normal' }).bg), 'Normal bg after background=light')
  t.eq(palette.purple, t.hex(vim.api.nvim_get_hl(0, { name = '@keyword' }).fg), '@keyword fg after background=light')
  vim.o.background = 'dark'
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
