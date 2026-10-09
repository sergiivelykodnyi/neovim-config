-- mini.nvim modules used by this config: statusline, icons, ai, surround.
local M = {}

M.detect = { 'mini.statusline', 'mini.icons', 'mini.ai', 'mini.surround' }

---@param p table palette
---@return table<string, vim.api.keyset.highlight>
function M.get(p)
  return {
    -- statusline: mode block in a syntax color on the list selection background
    MiniStatuslineModeNormal = { fg = p.blue, bg = p.bg_select },
    MiniStatuslineModeInsert = { fg = p.green, bg = p.bg_select },
    MiniStatuslineModeVisual = { fg = p.purple, bg = p.bg_select },
    MiniStatuslineModeReplace = { fg = p.red, bg = p.bg_select },
    MiniStatuslineModeCommand = { fg = p.orange, bg = p.bg_select },
    MiniStatuslineModeOther = { fg = p.cyan, bg = p.bg_select },
    MiniStatuslineDevinfo = { fg = p.status_fg, bg = p.bg_tab },
    MiniStatuslineFilename = { fg = p.status_fg, bg = p.bg },
    MiniStatuslineFileinfo = { fg = p.status_fg, bg = p.bg_tab },
    MiniStatuslineInactive = { fg = p.inactive_fg, bg = p.bg },

    -- icons
    MiniIconsAzure = { fg = p.blue },
    MiniIconsBlue = { fg = p.blue },
    MiniIconsCyan = { fg = p.cyan },
    MiniIconsGreen = { fg = p.green },
    MiniIconsGrey = { fg = p.comment },
    MiniIconsOrange = { fg = p.orange },
    MiniIconsPurple = { fg = p.purple },
    MiniIconsRed = { fg = p.red },
    MiniIconsYellow = { fg = p.yellow },

    -- surround flash
    MiniSurround = { bg = p.search },

    -- cursorword (editor.wordHighlightBackground), in case the module is turned on
    MiniCursorword = { bg = p.word_highlight },
    MiniCursorwordCurrent = { bg = p.word_highlight },
  }
end

return M
