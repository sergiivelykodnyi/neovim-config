-- Builds the full highlight table: core groups, then enabled integrations.
local util = require 'apple.util'

local M = {}

-- Always applied.
M.core = { 'editor', 'syntax', 'treesitter', 'lsp' }

-- Applied when the plugin is found, or forced with opts.integrations.
-- Each module exports `detect` (module names for util.has_plugin) and `get`.
M.integrations = { 'telescope', 'blink', 'gitsigns', 'which_key', 'todo_comments', 'mini', 'fidget', 'mason' }

-- Is this integration on? User option wins, then plugin detection.
---@param name string
---@param opts table
---@return boolean
function M.enabled(name, opts)
  local forced = (opts.integrations or {})[name]
  if forced ~= nil then return forced end
  return util.has_plugin(require('apple.groups.' .. name).detect)
end

-- Merge every group file into one table. Later files win.
---@param p table palette
---@param opts table options
---@return table<string, vim.api.keyset.highlight>
function M.get(p, opts)
  local groups = {}
  local function add(name)
    for group, def in pairs(require('apple.groups.' .. name).get(p, opts)) do
      groups[group] = def
    end
  end
  for _, name in ipairs(M.core) do
    add(name)
  end
  for _, name in ipairs(M.integrations) do
    if M.enabled(name, opts) then add(name) end
  end
  return groups
end

return M
