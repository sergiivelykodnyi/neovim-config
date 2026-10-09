-- telescope.nvim
local M = {}

M.detect = 'telescope'

---@param p table palette
---@return table<string, vim.api.keyset.highlight>
function M.get(p)
  return {
    TelescopeSelection = { bg = p.bg_select },
  }
end

return M
