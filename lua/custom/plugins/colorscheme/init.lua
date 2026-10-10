-- One Dark Pro Night Flat colorscheme for Neovim.
-- Requiring this module applies the theme. There are no options.
-- To apply it again later, run `:colorscheme onedark` (colors/onedark.lua calls load()).
-- A second require() does nothing, because Lua caches the module.
-- Colors: palette.lua. Highlight groups: groups/*.lua.
local M = {}

local root = 'custom.plugins.colorscheme'

-- Always applied.
local core = { 'editor', 'syntax', 'treesitter', 'lsp' }

-- Applied when the plugin is found on the runtimepath.
-- Each groups/<name>.lua exports `detect` (module names for util.has_plugin) and `get(p)`.
M.integrations = { 'telescope', 'blink', 'gitsigns', 'which_key', 'todo_comments', 'mini', 'fidget', 'mason' }
vim.list_extend(M.integrations, { 'indent_blankline', 'neo_tree', 'dap', 'rainbow_delimiters' })

-- Integrations applied since the last load(), and ones that failed (so the error is reported once).
local done = {}

-- Apply the groups of every detected integration that was not applied yet.
-- Returns true when at least one integration was added.
---@return boolean
function M.apply_new_integrations()
  local p = require(root .. '.palette')
  local util = require(root .. '.util')
  local added = false
  for _, name in ipairs(M.integrations) do
    if not done[name] then
      local ok, result = pcall(function()
        local mod = require(root .. '.groups.' .. name)
        if not util.has_plugin(mod.detect) then return false end
        util.apply(mod.get(p))
        return true
      end)
      if not ok then
        done[name] = true
        vim.notify(('colorscheme: integration "%s" failed: %s'):format(name, result), vim.log.levels.ERROR)
      elseif result then
        done[name] = true
        added = true
      end
    end
  end
  return added
end

-- Plugins are usually added to the runtimepath after this module ran in init.lua,
-- so detection misses them. Check again at VimEnter, when every plugin is there.
local function reapply_after_startup()
  if vim.v.vim_did_enter == 1 then return end
  vim.api.nvim_create_autocmd('VimEnter', {
    group = vim.api.nvim_create_augroup('onedark-startup', { clear = true }),
    once = true,
    desc = 'Apply colorscheme groups for plugins loaded after the theme',
    callback = function()
      if vim.g.colors_name == 'onedark' then M.apply_new_integrations() end
    end,
  })
end

-- Apply the whole theme.
function M.load()
  local p = require(root .. '.palette')
  local util = require(root .. '.util')

  vim.cmd 'highlight clear'
  vim.g.colors_name = 'onedark'

  for _, name in ipairs(core) do
    util.apply(require(root .. '.groups.' .. name).get(p))
  end

  for i, color in ipairs(p.terminal) do
    vim.g['terminal_color_' .. (i - 1)] = color
  end

  done = {}
  M.apply_new_integrations()
  reapply_after_startup()
end

M.load()

return M
