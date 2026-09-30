-- indent-blankline.nvim (module `ibl`): indent guides.
local M = {}

M.detect = 'ibl'

---@param p table palette
---@param _ table options (unused here)
function M.get(p, _)
  return {
    IblIndent = { fg = p.border },
    IblWhitespace = { fg = p.border },
    IblScope = { fg = p.comment },
    -- Old names, still used by some configs
    IndentBlanklineChar = { fg = p.border },
    IndentBlanklineContextChar = { fg = p.comment },
  }
end

return M
