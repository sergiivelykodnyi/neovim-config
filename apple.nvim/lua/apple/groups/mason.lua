-- mason.nvim: the :Mason package window.
local M = {}

M.detect = 'mason'

---@param p table palette
---@param _ table options (unused here)
function M.get(p, _)
  return {
    MasonNormal = { fg = p.fg, bg = p.bg_alt },
    MasonHeader = { fg = p.bg, bg = p.blue, bold = true },
    MasonHeaderSecondary = { fg = p.bg, bg = p.orange, bold = true },
    MasonHeading = { fg = p.fg, bold = true },
    MasonHighlight = { fg = p.blue },
    MasonHighlightBlock = { fg = p.bg, bg = p.blue },
    MasonHighlightBlockBold = { fg = p.bg, bg = p.blue, bold = true },
    MasonHighlightSecondary = { fg = p.orange },
    MasonHighlightBlockSecondary = { fg = p.bg, bg = p.orange },
    MasonHighlightBlockBoldSecondary = { fg = p.bg, bg = p.orange, bold = true },
    MasonLink = { fg = p.blue, underline = true },
    MasonMuted = { fg = p.comment },
    MasonMutedBlock = { fg = p.fg, bg = p.border },
    MasonMutedBlockBold = { fg = p.fg, bg = p.border, bold = true },
    MasonError = { fg = p.red },
    MasonWarning = { fg = p.orange },
  }
end

return M
