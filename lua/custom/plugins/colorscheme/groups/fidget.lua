-- fidget.nvim: LSP progress messages in the corner.
local M = {}

M.detect = 'fidget'

---@param p table palette
---@return table<string, vim.api.keyset.highlight>
function M.get(p)
  return {
    FidgetTitle = { fg = p.fg },
    FidgetTask = { fg = p.comment },
    FidgetNormal = { fg = p.comment, bg = p.none },
  }
end

return M
