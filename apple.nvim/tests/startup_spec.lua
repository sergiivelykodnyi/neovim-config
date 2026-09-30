local t = require 'helpers'
local palette = require 'apple.palette'

local root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h:h')

-- Run a real Neovim with the given init.lua lines and return what it prints.
-- VimEnter already happened in this runner, so startup behavior needs a child process.
local function run_nvim(init_lines)
  local tmp = vim.fn.tempname()
  vim.fn.mkdir(tmp .. '/fake/lua/telescope', 'p')
  vim.fn.writefile({ 'return {}' }, tmp .. '/fake/lua/telescope/init.lua')
  local lines = { ('vim.opt.runtimepath:prepend(%q)'):format(root), ('FAKE = %q'):format(tmp .. '/fake') }
  vim.list_extend(lines, init_lines)
  vim.fn.writefile(lines, tmp .. '/init.lua')
  local result = vim.system({ vim.v.progpath, '--clean', '--headless', '-u', tmp .. '/init.lua' }, { text = true }):wait(10000)
  vim.fn.delete(tmp, 'rf')
  t.eq(0, result.code, 'nvim exit code, stderr: ' .. tostring(result.stderr))
  return result.stdout
end

-- Prints "<TelescopeNormal bg>|<Normal bg>" once startup is finished.
local report = {
  "vim.api.nvim_create_autocmd('VimEnter', {",
  '  callback = function()',
  '    vim.schedule(function()',
  "      local tele = vim.api.nvim_get_hl(0, { name = 'TelescopeNormal' })",
  "      local normal = vim.api.nvim_get_hl(0, { name = 'Normal' })",
  "      local function hex(n) return n and ('#%06X'):format(n) or 'none' end",
  "      io.stdout:write(hex(tele.bg) .. '|' .. hex(normal.bg))",
  "      vim.cmd 'qa!'",
  '    end)',
  '  end,',
  '})',
}

-- Plugin managers often add plugins after `:colorscheme` ran in init.lua.
-- The theme must still pick those plugins up once startup is finished.
t.test('integrations added after :colorscheme are applied at VimEnter', function()
  local out = run_nvim(vim.list_extend({
    "vim.cmd.colorscheme 'apple'",
    -- The plugin appears only after the colorscheme was loaded.
    'vim.opt.runtimepath:prepend(FAKE)',
  }, report))
  t.eq(palette.dark.bg_alt .. '|' .. palette.dark.bg, out)
end)

-- Users often override a group right after `:colorscheme`. The VimEnter step
-- must only add the new integration groups, not reset everything.
t.test('VimEnter step keeps user overrides made after :colorscheme', function()
  local out = run_nvim(vim.list_extend({
    "vim.cmd.colorscheme 'apple'",
    "vim.api.nvim_set_hl(0, 'Normal', { bg = 'NONE' })",
    'vim.opt.runtimepath:prepend(FAKE)',
  }, report))
  t.eq(palette.dark.bg_alt .. '|none', out)
end)
