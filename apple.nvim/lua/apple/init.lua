-- The "apple" colorscheme: Apple system colors for Neovim.
-- `setup()` stores options. `:colorscheme apple` (colors/apple.lua) calls `load()`.
local M = {}

-- True while load() runs. Setting 'background' inside load() makes Neovim
-- run `:colorscheme apple` again; this flag stops that second run.
local loading = false

-- Store options. Optional: `:colorscheme apple` works with defaults.
---@param opts? table see apple.config defaults
function M.setup(opts) require('apple.config').extend(opts) end

-- Which palette to use: the option, or 'background' when the option is 'auto'.
---@return 'dark'|'light'
local function resolve_flavor(opts)
  if opts.flavor == 'dark' or opts.flavor == 'light' then return opts.flavor end
  return vim.o.background == 'light' and 'light' or 'dark'
end

-- Names of the integrations that were on during the last load().
local applied_integrations = {}

-- Which integrations are on right now, as a set.
local function enabled_integrations(opts)
  local groups = require 'apple.groups'
  local set = {}
  for _, name in ipairs(groups.integrations) do
    if groups.enabled(name, opts) then set[name] = true end
  end
  return set
end

local function do_load()
  local opts = require('apple.config').options
  local flavor = resolve_flavor(opts)

  vim.cmd 'highlight clear'
  vim.g.colors_name = 'apple'

  local palette = require('apple.palette')[flavor]
  local groups = require('apple.groups').get(palette, opts)
  if opts.on_highlights then opts.on_highlights(groups, palette) end
  applied_integrations = enabled_integrations(opts)

  require('apple.util').apply(groups)
  for i, color in ipairs(palette.terminal) do
    vim.g['terminal_color_' .. (i - 1)] = color
  end

  -- A forced flavor also sets 'background', so plugins and Neovim agree.
  -- This must happen after load() returns: when Neovim reloads the
  -- colorscheme because 'background' changed, it restores the user's value
  -- if the colorscheme changes it during that reload. The scheduled set
  -- triggers one more reload, which then finds nothing to change.
  -- In 'auto' mode we never touch 'background', so the theme keeps
  -- following the terminal.
  if vim.o.background ~= flavor then
    vim.schedule(function()
      -- Read the option again: setup() may have changed it in the meantime.
      local wanted = require('apple.config').options.flavor
      if wanted ~= 'dark' and wanted ~= 'light' then return end
      if vim.g.colors_name == 'apple' and vim.o.background ~= wanted then vim.o.background = wanted end
    end)
  end
end

-- Apply the groups of integrations that were not on during the last load().
-- Nothing else is touched, so highlights the user set after `:colorscheme`
-- stay as they are. Returns true when something was added.
function M.apply_new_integrations()
  local opts = require('apple.config').options
  local now = enabled_integrations(opts)
  local new = {}
  for name in pairs(now) do
    if not applied_integrations[name] then new[#new + 1] = name end
  end
  if #new == 0 then return false end

  local palette = require('apple.palette')[resolve_flavor(opts)]
  -- Build the full table, so on_highlights sees the same input as in load().
  local all = require('apple.groups').get(palette, opts)
  if opts.on_highlights then opts.on_highlights(all, palette) end

  local subset = {}
  for _, name in ipairs(new) do
    for group in pairs(require('apple.groups.' .. name).get(palette, opts)) do
      subset[group] = all[group]
    end
  end
  require('apple.util').apply(subset)
  applied_integrations = now
  return true
end

-- Plugins are often added to the runtimepath after `:colorscheme` ran in
-- init.lua, so integration detection misses them. When the colorscheme loads
-- during startup, check again at VimEnter, when every plugin is there.
local function reapply_after_startup()
  if vim.v.vim_did_enter == 1 then return end
  vim.api.nvim_create_autocmd('VimEnter', {
    group = vim.api.nvim_create_augroup('apple-startup', { clear = true }),
    once = true,
    desc = 'Add integrations for plugins that were loaded after :colorscheme apple',
    callback = function()
      if vim.g.colors_name == 'apple' then M.apply_new_integrations() end
    end,
  })
end

-- Apply the colorscheme for the current options and 'background'.
function M.load()
  if loading then return end
  loading = true
  local ok, err = pcall(do_load)
  loading = false
  if not ok then error(err, 0) end
  reapply_after_startup()
end

return M
