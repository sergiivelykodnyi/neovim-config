-- which-key.nvim: key hint popup.
local M = {}

M.detect = 'which-key'

---@param p table palette
---@param _ table options (unused here)
function M.get(p, _)
  return {
    WhichKey = { fg = p.blue, bold = true },
    WhichKeyGroup = { fg = p.teal },
    WhichKeyDesc = { fg = p.fg },
    WhichKeySeparator = { fg = p.comment },
    WhichKeyValue = { fg = p.comment },
    WhichKeyIcon = { fg = p.blue },
    WhichKeyNormal = { fg = p.fg, bg = p.bg_alt },
    WhichKeyBorder = { fg = p.border, bg = p.bg_alt },
    WhichKeyTitle = { fg = p.fg, bg = p.bg_alt, bold = true },
  }
end

return M
