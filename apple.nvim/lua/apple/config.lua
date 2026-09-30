-- Options for the apple colorscheme.
local M = {}

---@class AppleOptions
---@field flavor 'auto'|'dark'|'light' 'auto' follows 'background'
---@field styles table<string, vim.api.keyset.highlight> extra style per syntax kind
---@field integrations table<string, boolean> force an integration on or off
---@field on_highlights? fun(groups: table, palette: table) change groups before they are applied

---@type AppleOptions
M.defaults = {
  flavor = 'auto',
  styles = {
    comments = {},
    keywords = { bold = true },
    functions = {},
    strings = {},
  },
  integrations = {},
  on_highlights = nil,
}

---@type AppleOptions
M.options = vim.deepcopy(M.defaults)

-- Build the options from the defaults and the user table.
-- Tables under `styles` replace the default (so `keywords = {}` removes bold).
-- Everything else is deep-merged.
---@param opts? table
---@return AppleOptions
function M.extend(opts)
  opts = opts or {}
  local options = vim.tbl_deep_extend('force', vim.deepcopy(M.defaults), opts)
  for key, style in pairs(opts.styles or {}) do
    options.styles[key] = vim.deepcopy(style)
  end
  M.options = options
  return options
end

return M
