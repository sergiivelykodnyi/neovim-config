-- mini.nvim modules used in this config: statusline, icons, surround, ai.
local M = {}

-- Any lua/mini/*.lua file on the runtimepath counts.
M.detect = 'mini'

---@param p table palette
---@param _ table options (unused here)
function M.get(p, _)
  return {
    -- mini.statusline: a colored block per mode, grays for the other sections
    MiniStatuslineModeNormal = { fg = p.bg, bg = p.blue, bold = true },
    MiniStatuslineModeInsert = { fg = p.bg, bg = p.green, bold = true },
    MiniStatuslineModeVisual = { fg = p.bg, bg = p.purple, bold = true },
    MiniStatuslineModeReplace = { fg = p.bg, bg = p.red, bold = true },
    MiniStatuslineModeCommand = { fg = p.bg, bg = p.orange, bold = true },
    MiniStatuslineModeOther = { fg = p.bg, bg = p.teal, bold = true },
    MiniStatuslineDevinfo = { fg = p.fg, bg = p.border },
    MiniStatuslineFilename = { fg = p.fg, bg = p.bg_alt },
    MiniStatuslineFileinfo = { fg = p.fg, bg = p.border },
    MiniStatuslineInactive = { fg = p.comment, bg = p.bg_alt },

    -- mini.icons
    MiniIconsAzure = { fg = p.blue },
    MiniIconsBlue = { fg = p.blue },
    MiniIconsCyan = { fg = p.teal },
    MiniIconsGreen = { fg = p.green },
    MiniIconsGrey = { fg = p.comment },
    MiniIconsOrange = { fg = p.orange },
    MiniIconsPurple = { fg = p.purple },
    MiniIconsRed = { fg = p.red },
    MiniIconsYellow = { fg = p.yellow },

    -- mini.surround
    MiniSurround = { fg = p.search_fg, bg = p.cur_search },

    -- mini.pick / mini.notify / mini.indentscope (cheap to add, used by many configs)
    MiniPickBorder = { fg = p.border, bg = p.bg_alt },
    MiniPickBorderBusy = { fg = p.orange, bg = p.bg_alt },
    MiniPickBorderText = { fg = p.fg, bg = p.bg_alt, bold = true },
    MiniPickHeader = { fg = p.blue, bg = p.bg_alt },
    MiniPickMatchCurrent = { fg = p.selection_fg, bg = p.selection },
    MiniPickMatchMarked = { fg = p.purple, bg = p.bg_alt },
    MiniPickMatchRanges = { fg = p.blue, bold = true },
    MiniPickNormal = { fg = p.fg, bg = p.bg_alt },
    MiniPickPreviewLine = { bg = p.border },
    MiniPickPrompt = { fg = p.blue, bg = p.bg_alt },
    MiniNotifyBorder = { fg = p.border, bg = p.bg_alt },
    MiniNotifyNormal = { fg = p.fg, bg = p.bg_alt },
    MiniNotifyTitle = { fg = p.blue, bg = p.bg_alt, bold = true },
    MiniIndentscopeSymbol = { fg = p.line_nr },
  }
end

return M
