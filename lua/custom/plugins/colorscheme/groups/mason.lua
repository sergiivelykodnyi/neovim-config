-- mason.nvim window.
local M = {}

M.detect = 'mason'

---@param p table palette
---@return table<string, vim.api.keyset.highlight>
function M.get(p)
  return {
    MasonNormal = { fg = p.fg, bg = p.bg_float },
    MasonHeader = { fg = p.bg, bg = p.blue },
    MasonHeaderSecondary = { fg = p.bg, bg = p.orange },
    MasonHeading = { fg = p.blue },
    MasonHighlight = { fg = p.green },
    MasonHighlightBlock = { fg = p.bg, bg = p.green },
    MasonHighlightBlockBold = { fg = p.bg, bg = p.green },
    MasonHighlightSecondary = { fg = p.orange },
    MasonHighlightBlockSecondary = { fg = p.bg, bg = p.orange },
    MasonHighlightBlockBoldSecondary = { fg = p.bg, bg = p.orange },
    MasonLink = { fg = p.blue, underline = true },
    MasonMuted = { fg = p.comment },
    MasonMutedBlock = { fg = p.comment, bg = p.bg_select },
    MasonMutedBlockBold = { fg = p.fg, bg = p.bg_select },
    MasonError = { fg = p.diag_error },
    MasonWarning = { fg = p.diag_warn },
  }
end

return M
