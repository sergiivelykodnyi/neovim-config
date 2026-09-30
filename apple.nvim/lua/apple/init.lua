-- The "apple" colorscheme: Apple system colors for Neovim.
-- `setup()` stores options. `:colorscheme apple` (colors/apple.lua) calls `load()`.
local M = {}

-- True while load() runs. Setting 'background' inside load() makes Neovim
-- run `:colorscheme apple` again; this flag stops that second run.
local loading = false

-- Store options. Optional: `:colorscheme apple` works with defaults.
---@param opts? table see apple.config defaults
function M.setup(opts)
  require('apple.config').extend(opts)
end

-- Which palette to use: the option, or 'background' when the option is 'auto'.
---@return 'dark'|'light'
local function resolve_flavor(opts)
  if opts.flavor == 'dark' or opts.flavor == 'light' then return opts.flavor end
  return vim.o.background == 'light' and 'light' or 'dark'
end

local function do_load()
  local opts = require('apple.config').options
  local flavor = resolve_flavor(opts)

  vim.cmd 'highlight clear'
  vim.g.colors_name = 'apple'

  local palette = require('apple.palette')[flavor]
  local groups = require('apple.groups').get(palette, opts)
  if opts.on_highlights then opts.on_highlights(groups, palette) end

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
      if vim.g.colors_name == 'apple' and vim.o.background ~= flavor then vim.o.background = flavor end
    end)
  end
end

-- Apply the colorscheme for the current options and 'background'.
function M.load()
  if loading then return end
  loading = true
  local ok, err = pcall(do_load)
  loading = false
  if not ok then error(err, 0) end
end

return M
