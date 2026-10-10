-- Built-in UI groups. See :help highlight-groups.
-- The VSCode key for each color is in palette.lua.
local M = {}

---@param p table palette
---@return table<string, vim.api.keyset.highlight>
function M.get(p)
  return {
    Normal = { fg = p.fg, bg = p.bg },
    NormalNC = { fg = p.fg, bg = p.bg },
    NormalFloat = { fg = p.fg, bg = p.bg_float },
    FloatBorder = { fg = p.border, bg = p.bg_float },
    FloatTitle = { fg = p.blue, bg = p.bg_float },
    FloatFooter = { fg = p.comment, bg = p.bg_float },

    -- Cursor and current line
    Cursor = { fg = p.bg, bg = p.cursor },
    lCursor = { fg = p.bg, bg = p.cursor },
    CursorIM = { fg = p.bg, bg = p.cursor },
    TermCursor = { fg = p.bg, bg = p.cursor },
    CursorLine = { bg = p.bg_line },
    CursorColumn = { bg = p.bg_line },
    QuickFixLine = { bg = p.bg_line },
    ColorColumn = { bg = p.ruler },

    -- Gutter
    LineNr = { fg = p.line_nr },
    LineNrAbove = { fg = p.line_nr },
    LineNrBelow = { fg = p.line_nr },
    -- VSCode keeps the gutter of the current line on the editor background.
    CursorLineNr = { fg = p.fg, bg = p.bg },
    SignColumn = { bg = p.bg },
    CursorLineSign = { bg = p.bg },
    FoldColumn = { fg = p.line_nr, bg = p.bg },
    CursorLineFold = { fg = p.line_nr, bg = p.bg },
    Folded = { fg = p.comment, bg = p.bg_float },

    -- Selection and search
    Visual = { bg = p.selection },
    VisualNOS = { bg = p.selection },
    Search = { bg = p.search_other },
    CurSearch = { bg = p.search },
    IncSearch = { bg = p.search },
    Substitute = { bg = p.search },
    MatchParen = { bg = p.bracket_match },

    -- Invisible characters
    Whitespace = { fg = p.whitespace },
    NonText = { fg = p.whitespace },
    EndOfBuffer = { fg = p.whitespace },
    SpecialKey = { fg = p.whitespace },
    Conceal = { fg = p.comment },

    -- Popup menu
    Pmenu = { fg = p.fg, bg = p.bg_float },
    PmenuSel = { bg = p.bg_select },
    PmenuKind = { fg = p.comment, bg = p.bg_float },
    PmenuKindSel = { fg = p.comment, bg = p.bg_select },
    PmenuExtra = { fg = p.comment, bg = p.bg_float },
    PmenuExtraSel = { fg = p.comment, bg = p.bg_select },
    PmenuSbar = { bg = p.bg_float },
    PmenuThumb = { bg = p.scrollbar },
    PmenuMatch = { fg = p.blue, bg = p.bg_float },
    PmenuMatchSel = { fg = p.blue, bg = p.bg_select },
    WildMenu = { bg = p.bg_select },

    -- Status line, tabs, splits
    StatusLine = { fg = p.status_fg, bg = p.bg },
    StatusLineNC = { fg = p.inactive_fg, bg = p.bg },
    StatusLineTerm = { fg = p.status_fg, bg = p.bg },
    StatusLineTermNC = { fg = p.inactive_fg, bg = p.bg },
    WinSeparator = { fg = p.border },
    VertSplit = { fg = p.border },
    TabLine = { fg = p.inactive_fg, bg = p.bg },
    TabLineFill = { bg = p.bg },
    TabLineSel = { fg = p.tab_fg, bg = p.bg_tab },
    WinBar = { fg = p.fg, bg = p.bg },
    WinBarNC = { fg = p.inactive_fg, bg = p.bg },

    -- Messages
    Title = { fg = p.blue },
    Directory = { fg = p.blue },
    ErrorMsg = { fg = p.diag_error },
    WarningMsg = { fg = p.diag_warn },
    MoreMsg = { fg = p.green },
    Question = { fg = p.green },
    ModeMsg = { fg = p.fg },
    MsgArea = { fg = p.fg },
    MsgSeparator = { fg = p.border },

    -- Diff
    DiffAdd = { bg = p.diff_add_bg },
    DiffDelete = { bg = p.diff_delete_bg },
    DiffChange = { bg = p.diff_change_bg },
    DiffText = { bg = p.diff_text_bg },
    Added = { fg = p.green },
    Changed = { fg = p.yellow },
    Removed = { fg = p.red },

    -- Spelling
    SpellBad = { sp = p.diag_error, undercurl = true },
    SpellCap = { sp = p.diag_warn, undercurl = true },
    SpellLocal = { sp = p.diag_info, undercurl = true },
    SpellRare = { sp = p.diag_hint, undercurl = true },

    -- Misc
    Underlined = { underline = true },
    Error = { fg = p.error },
    Ignore = { fg = p.bg },
    healthSuccess = { fg = p.green },
    healthWarning = { fg = p.diag_warn },
    healthError = { fg = p.diag_error },
  }
end

return M
