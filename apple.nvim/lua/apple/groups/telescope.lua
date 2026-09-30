-- telescope.nvim: floating picker windows.
local M = {}

M.detect = 'telescope'

---@param p table palette
---@param _ table options (unused here)
function M.get(p, _)
  return {
    TelescopeNormal = { fg = p.fg, bg = p.bg_alt },
    TelescopeBorder = { fg = p.border, bg = p.bg_alt },
    TelescopeTitle = { fg = p.fg, bg = p.bg_alt, bold = true },
    TelescopePromptNormal = { fg = p.fg, bg = p.bg_alt },
    TelescopePromptBorder = { fg = p.border, bg = p.bg_alt },
    TelescopePromptTitle = { fg = p.bg, bg = p.blue, bold = true },
    TelescopePromptPrefix = { fg = p.blue, bg = p.bg_alt },
    TelescopePromptCounter = { fg = p.comment, bg = p.bg_alt },
    TelescopeResultsTitle = { fg = p.comment, bg = p.bg_alt },
    TelescopePreviewTitle = { fg = p.bg, bg = p.green, bold = true },
    TelescopeSelection = { fg = p.selection_fg, bg = p.selection },
    TelescopeSelectionCaret = { fg = p.selection_fg, bg = p.selection },
    TelescopeMultiSelection = { fg = p.purple, bg = p.bg_alt },
    TelescopeMultiIcon = { fg = p.purple },
    TelescopeMatching = { fg = p.blue, bold = true },
    TelescopeResultsComment = { fg = p.comment },
    TelescopeResultsDiffAdd = { fg = p.green },
    TelescopeResultsDiffChange = { fg = p.blue },
    TelescopeResultsDiffDelete = { fg = p.red },
    TelescopeResultsDiffUntracked = { fg = p.orange },
    TelescopePreviewLine = { bg = p.border },
    TelescopePreviewMatch = { fg = p.search_fg, bg = p.search },
  }
end

return M
