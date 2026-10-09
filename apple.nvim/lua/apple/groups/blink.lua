-- blink.cmp: completion menu, documentation and signature help.
local M = {}

M.detect = 'blink.cmp'

---@param p table palette
---@param _ table options (unused here)
function M.get(p, _)
  return {
    BlinkCmpMenu = { fg = p.fg, bg = p.bg_alt },
    BlinkCmpMenuBorder = { fg = p.border, bg = p.bg_alt },
    BlinkCmpMenuSelection = { fg = p.selection_fg, bg = p.selection },
    BlinkCmpScrollBarThumb = { bg = p.border },
    BlinkCmpScrollBarGutter = { bg = p.bg_alt },
    BlinkCmpLabel = { fg = p.fg },
    BlinkCmpLabelDeprecated = { fg = p.comment, strikethrough = true },
    BlinkCmpLabelMatch = { fg = p.blue, bold = true },
    BlinkCmpLabelDetail = { fg = p.comment },
    BlinkCmpLabelDescription = { fg = p.comment },
    BlinkCmpSource = { fg = p.comment },
    BlinkCmpGhostText = { fg = p.comment },
    BlinkCmpDoc = { fg = p.fg, bg = p.bg_alt },
    BlinkCmpDocBorder = { fg = p.border, bg = p.bg_alt },
    BlinkCmpDocSeparator = { fg = p.border, bg = p.bg_alt },
    BlinkCmpDocCursorLine = { bg = p.border },
    BlinkCmpSignatureHelp = { fg = p.fg, bg = p.bg_alt },
    BlinkCmpSignatureHelpBorder = { fg = p.border, bg = p.bg_alt },
    BlinkCmpSignatureHelpActiveParameter = { bg = p.border, bold = true },

    -- Item kinds: same colors as the syntax groups they stand for
    BlinkCmpKind = { fg = p.teal },
    BlinkCmpKindText = { fg = p.fg },
    BlinkCmpKindMethod = { fg = p.blue },
    BlinkCmpKindFunction = { fg = p.blue },
    BlinkCmpKindConstructor = { fg = p.yellow },
    BlinkCmpKindField = { fg = p.red },
    BlinkCmpKindVariable = { fg = p.red },
    BlinkCmpKindClass = { fg = p.yellow },
    BlinkCmpKindInterface = { fg = p.yellow },
    BlinkCmpKindModule = { fg = p.yellow },
    BlinkCmpKindProperty = { fg = p.red },
    BlinkCmpKindUnit = { fg = p.orange },
    BlinkCmpKindValue = { fg = p.orange },
    BlinkCmpKindEnum = { fg = p.yellow },
    BlinkCmpKindKeyword = { fg = p.purple },
    BlinkCmpKindSnippet = { fg = p.pink },
    BlinkCmpKindColor = { fg = p.pink },
    BlinkCmpKindFile = { fg = p.blue },
    BlinkCmpKindReference = { fg = p.pink },
    BlinkCmpKindFolder = { fg = p.blue },
    BlinkCmpKindEnumMember = { fg = p.cyan },
    BlinkCmpKindConstant = { fg = p.orange },
    BlinkCmpKindStruct = { fg = p.yellow },
    BlinkCmpKindEvent = { fg = p.pink },
    BlinkCmpKindOperator = { fg = p.cyan },
    BlinkCmpKindTypeParameter = { fg = p.yellow },
  }
end

return M
