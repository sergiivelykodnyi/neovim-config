local t = require 'helpers'
local palette = require 'apple.palette'

-- Plugin managers often add plugins after `:colorscheme` ran in init.lua.
-- The theme must still pick those plugins up once startup is finished.
-- This runs a real Neovim, because VimEnter already happened in this runner.
t.test('integrations added after :colorscheme are applied at VimEnter', function()
  local root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h:h')
  local tmp = vim.fn.tempname()
  vim.fn.mkdir(tmp .. '/fake/lua/telescope', 'p')
  vim.fn.writefile({ 'return {}' }, tmp .. '/fake/lua/telescope/init.lua')
  vim.fn.writefile({
    ('vim.opt.runtimepath:prepend(%q)'):format(root),
    "vim.cmd.colorscheme 'apple'",
    -- The plugin appears only after the colorscheme was loaded.
    ('vim.opt.runtimepath:prepend(%q)'):format(tmp .. '/fake'),
    "vim.api.nvim_create_autocmd('VimEnter', {",
    '  callback = function()',
    '    vim.schedule(function()',
    "      local def = vim.api.nvim_get_hl(0, { name = 'TelescopeNormal' })",
    "      io.stdout:write(def.bg and ('#%06X'):format(def.bg) or 'none')",
    "      vim.cmd 'qa!'",
    '    end)',
    '  end,',
    '})',
  }, tmp .. '/init.lua')
  local out = vim.fn.system { 'nvim', '--clean', '--headless', '-u', tmp .. '/init.lua' }
  vim.fn.delete(tmp, 'rf')
  t.eq(palette.dark.bg_alt, out, 'TelescopeNormal bg after startup')
end)
