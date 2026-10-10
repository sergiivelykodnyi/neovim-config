-- which-key.nvim
local M = {}

M.detect = 'which-key'

---@param p table palette
---@return table<string, vim.api.keyset.highlight>
function M.get(p)
  return {
    WhichKey = { fg = p.blue },
    WhichKeyGroup = { fg = p.purple },
    WhichKeyDesc = { fg = p.fg },
    WhichKeySeparator = { fg = p.comment },
    WhichKeyIcon = { fg = p.cyan },
    WhichKeyValue = { fg = p.comment },
    WhichKeyNormal = { fg = p.fg, bg = p.bg_float },
    WhichKeyBorder = { fg = p.border, bg = p.bg_float },
    WhichKeyTitle = { fg = p.blue, bg = p.bg_float },
  }
end

return M
