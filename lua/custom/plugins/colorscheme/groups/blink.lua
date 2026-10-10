-- blink.cmp. Mirrors the VSCode suggest widget. Kind colors follow the syntax colors.
local M = {}

M.detect = 'blink.cmp'

---@param p table palette
---@return table<string, vim.api.keyset.highlight>
function M.get(p)
  return {
    BlinkCmpMenu = { fg = p.fg, bg = p.bg_float },
    BlinkCmpMenuBorder = { fg = p.border, bg = p.bg_float },
    BlinkCmpMenuSelection = { bg = p.bg_select },
    BlinkCmpScrollBarThumb = { bg = p.scrollbar },
    BlinkCmpScrollBarGutter = { bg = p.bg_float },

    BlinkCmpLabel = { fg = p.fg },
    BlinkCmpLabelDeprecated = { fg = p.comment, strikethrough = true },
    BlinkCmpLabelMatch = { fg = p.blue },
    BlinkCmpLabelDetail = { fg = p.comment },
    BlinkCmpLabelDescription = { fg = p.comment },
    BlinkCmpSource = { fg = p.comment },
    BlinkCmpGhostText = { fg = p.comment },

    BlinkCmpDoc = { fg = p.fg, bg = p.bg_float },
    BlinkCmpDocBorder = { fg = p.border, bg = p.bg_float },
    BlinkCmpDocSeparator = { fg = p.border, bg = p.bg_float },
    BlinkCmpDocCursorLine = { bg = p.bg_line },
    BlinkCmpSignatureHelp = { fg = p.fg, bg = p.bg_float },
    BlinkCmpSignatureHelpBorder = { fg = p.border, bg = p.bg_float },
    BlinkCmpSignatureHelpActiveParameter = { bg = p.word_highlight },

    BlinkCmpKind = { fg = p.fg },
    BlinkCmpKindText = { fg = p.fg },
    BlinkCmpKindMethod = { fg = p.blue },
    BlinkCmpKindFunction = { fg = p.blue },
    BlinkCmpKindConstructor = { fg = p.blue },
    BlinkCmpKindField = { fg = p.red },
    BlinkCmpKindVariable = { fg = p.red },
    BlinkCmpKindProperty = { fg = p.red },
    BlinkCmpKindClass = { fg = p.yellow },
    BlinkCmpKindInterface = { fg = p.yellow },
    BlinkCmpKindStruct = { fg = p.yellow },
    BlinkCmpKindModule = { fg = p.yellow },
    BlinkCmpKindTypeParameter = { fg = p.yellow },
    BlinkCmpKindUnit = { fg = p.orange },
    BlinkCmpKindValue = { fg = p.orange },
    BlinkCmpKindConstant = { fg = p.orange },
    BlinkCmpKindEnum = { fg = p.yellow },
    BlinkCmpKindEnumMember = { fg = p.cyan },
    BlinkCmpKindKeyword = { fg = p.purple },
    BlinkCmpKindOperator = { fg = p.cyan },
    BlinkCmpKindSnippet = { fg = p.green },
    BlinkCmpKindColor = { fg = p.orange },
    BlinkCmpKindFile = { fg = p.fg },
    BlinkCmpKindFolder = { fg = p.blue },
    BlinkCmpKindReference = { fg = p.fg },
    BlinkCmpKindEvent = { fg = p.red },
  }
end

return M
