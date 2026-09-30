-- Highlight groups for the editor UI: windows, menus, status line, diff, spelling.
local M = {}

---@param p table palette
---@param _ table options (unused here)
function M.get(p, _)
  return {
    -- Windows and text
    Normal = { fg = p.fg, bg = p.bg },
    NormalNC = { fg = p.fg, bg = p.bg },
    NormalFloat = { fg = p.fg, bg = p.bg_alt },
    FloatBorder = { fg = p.border, bg = p.bg_alt },
    FloatTitle = { fg = p.fg, bg = p.bg_alt, bold = true },
    FloatFooter = { fg = p.comment, bg = p.bg_alt },
    FloatShadow = { bg = p.border, blend = 80 },
    FloatShadowThrough = { bg = p.border, blend = 100 },
    WinSeparator = { fg = p.border },
    EndOfBuffer = { fg = p.bg },
    NonText = { fg = p.border },
    Whitespace = { fg = p.border },
    SpecialKey = { fg = p.border },
    Conceal = { fg = p.comment },
    Directory = { fg = p.blue },
    Title = { fg = p.fg, bold = true },
    Underlined = { underline = true },

    -- Cursor and lines
    Cursor = { fg = p.bg, bg = p.cursor },
    lCursor = { fg = p.bg, bg = p.cursor },
    CursorIM = { fg = p.bg, bg = p.cursor },
    TermCursor = { fg = p.bg, bg = p.cursor },
    CursorLine = { bg = p.bg_alt },
    CursorColumn = { bg = p.bg_alt },
    ColorColumn = { bg = p.bg_alt },
    CursorLineNr = { fg = p.fg, bold = true },
    CursorLineSign = { bg = p.none },
    CursorLineFold = { fg = p.line_nr, bg = p.none },
    LineNr = { fg = p.line_nr },
    LineNrAbove = { fg = p.line_nr },
    LineNrBelow = { fg = p.line_nr },
    SignColumn = { fg = p.line_nr, bg = p.none },
    FoldColumn = { fg = p.line_nr, bg = p.none },
    Folded = { fg = p.comment, bg = p.bg_alt },
    MatchParen = { bg = p.border, bold = true },

    -- Selection and search
    Visual = { fg = p.selection_fg, bg = p.selection },
    VisualNOS = { fg = p.selection_fg, bg = p.selection },
    Search = { fg = p.search_fg, bg = p.search },
    CurSearch = { fg = p.search_fg, bg = p.cur_search },
    IncSearch = { fg = p.search_fg, bg = p.cur_search },
    Substitute = { fg = p.search_fg, bg = p.cur_search },

    -- Popup menu and wild menu
    Pmenu = { fg = p.fg, bg = p.bg_alt },
    PmenuSel = { fg = p.selection_fg, bg = p.selection },
    PmenuKind = { fg = p.teal, bg = p.bg_alt },
    PmenuKindSel = { fg = p.selection_fg, bg = p.selection },
    PmenuExtra = { fg = p.comment, bg = p.bg_alt },
    PmenuExtraSel = { fg = p.selection_fg, bg = p.selection },
    PmenuMatch = { fg = p.blue, bg = p.bg_alt, bold = true },
    PmenuMatchSel = { fg = p.selection_fg, bg = p.selection, bold = true },
    PmenuSbar = { bg = p.bg_alt },
    PmenuThumb = { bg = p.border },
    WildMenu = { fg = p.selection_fg, bg = p.selection },
    ComplMatchIns = { fg = p.comment },

    -- Status line, win bar, tab line
    StatusLine = { fg = p.fg, bg = p.bg_alt },
    StatusLineNC = { fg = p.comment, bg = p.bg_alt },
    StatusLineTerm = { fg = p.fg, bg = p.bg_alt },
    StatusLineTermNC = { fg = p.comment, bg = p.bg_alt },
    WinBar = { fg = p.fg, bg = p.bg_alt, bold = true },
    WinBarNC = { fg = p.comment, bg = p.bg_alt },
    TabLine = { fg = p.comment, bg = p.bg_alt },
    TabLineSel = { fg = p.fg, bg = p.bg, bold = true },
    TabLineFill = { bg = p.bg_alt },

    -- Messages
    ErrorMsg = { fg = p.red },
    WarningMsg = { fg = p.orange },
    ModeMsg = { fg = p.fg, bold = true },
    MoreMsg = { fg = p.green },
    OkMsg = { fg = p.green },
    Question = { fg = p.blue },
    MsgArea = { fg = p.fg },
    MsgSeparator = { fg = p.border, bg = p.bg_alt },
    QuickFixLine = { bg = p.bg_alt, bold = true },
    qfLineNr = { fg = p.line_nr },
    qfFileName = { fg = p.blue },
    NvimInternalError = { fg = p.bg, bg = p.red },

    -- Diff
    DiffAdd = { bg = p.diff_add_bg },
    DiffChange = { bg = p.diff_change_bg },
    DiffDelete = { fg = p.red, bg = p.diff_delete_bg },
    DiffText = { bg = p.diff_text_bg },
    Added = { fg = p.green },
    Changed = { fg = p.blue },
    Removed = { fg = p.red },

    -- Spelling
    SpellBad = { undercurl = true, sp = p.red },
    SpellCap = { undercurl = true, sp = p.blue },
    SpellRare = { undercurl = true, sp = p.purple },
    SpellLocal = { undercurl = true, sp = p.teal },

    -- Misc
    SnippetTabstop = { bg = p.bg_alt },
    healthError = { fg = p.red },
    healthSuccess = { fg = p.green },
    healthWarning = { fg = p.orange },
    RedrawDebugClear = { bg = p.search },
    RedrawDebugComposed = { bg = p.diff_add_bg },
    RedrawDebugRecompose = { bg = p.diff_delete_bg },
  }
end

return M
