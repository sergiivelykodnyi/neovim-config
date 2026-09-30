-- fidget.nvim: LSP progress messages in the corner.
local M = {}

M.detect = 'fidget'

---@param p table palette
---@param _ table options (unused here)
function M.get(p, _)
  return {
    FidgetTitle = { fg = p.blue, bold = true },
    FidgetTask = { fg = p.comment },
    FidgetNormal = { fg = p.comment, bg = p.none },
  }
end

return M
