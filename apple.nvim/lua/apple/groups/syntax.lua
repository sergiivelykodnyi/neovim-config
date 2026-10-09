-- Highlight groups for Vim syntax and diagnostics.
-- Colors follow One Dark, with Apple colors: red variables, orange constants,
-- green strings, yellow types, blue functions, purple keywords, pink specials,
-- cyan operators and escape sequences.
local M = {}

-- Merge a user style into a base definition. The user style wins.
local function style(base, extra) return vim.tbl_extend('force', base, extra or {}) end

---@param p table palette
---@param opts table options
function M.get(p, opts)
  local s = opts.styles or {}
  return {
    -- Syntax
    Comment = style({ fg = p.comment }, s.comments),
    Constant = { fg = p.orange },
    String = style({ fg = p.green }, s.strings),
    Character = { fg = p.green },
    Number = { fg = p.orange },
    Boolean = { fg = p.orange },
    Float = { fg = p.orange },
    Identifier = { fg = p.red },
    Function = style({ fg = p.blue }, s.functions),
    Statement = style({ fg = p.purple }, s.keywords),
    Conditional = { link = 'Statement' },
    Repeat = { link = 'Statement' },
    Label = { link = 'Statement' },
    Operator = { fg = p.cyan },
    Keyword = style({ fg = p.purple }, s.keywords),
    Exception = { link = 'Statement' },
    PreProc = { fg = p.orange },
    Include = { link = 'Keyword' },
    Define = { link = 'PreProc' },
    Macro = { link = 'PreProc' },
    PreCondit = { link = 'PreProc' },
    Type = { fg = p.yellow },
    StorageClass = { link = 'Type' },
    Structure = { link = 'Type' },
    Typedef = { link = 'Type' },
    Special = { fg = p.pink },
    SpecialChar = { fg = p.cyan },
    Tag = { fg = p.red },
    Delimiter = { fg = p.fg },
    SpecialComment = { fg = p.comment, bold = true },
    Debug = { fg = p.orange },
    Ignore = { fg = p.comment },
    Error = { fg = p.red, bold = true },
    Todo = { fg = p.pink, bold = true },

    -- Diagnostics
    DiagnosticError = { fg = p.red },
    DiagnosticWarn = { fg = p.orange },
    DiagnosticInfo = { fg = p.blue },
    DiagnosticHint = { fg = p.comment },
    DiagnosticOk = { fg = p.green },
    DiagnosticVirtualTextError = { fg = p.red, bg = p.none },
    DiagnosticVirtualTextWarn = { fg = p.orange, bg = p.none },
    DiagnosticVirtualTextInfo = { fg = p.blue, bg = p.none },
    DiagnosticVirtualTextHint = { fg = p.comment, bg = p.none },
    DiagnosticVirtualTextOk = { fg = p.green, bg = p.none },
    DiagnosticUnderlineError = { undercurl = true, sp = p.red },
    DiagnosticUnderlineWarn = { undercurl = true, sp = p.orange },
    DiagnosticUnderlineInfo = { undercurl = true, sp = p.blue },
    DiagnosticUnderlineHint = { undercurl = true, sp = p.comment },
    DiagnosticUnderlineOk = { undercurl = true, sp = p.green },
    DiagnosticFloatingError = { fg = p.red, bg = p.bg_alt },
    DiagnosticFloatingWarn = { fg = p.orange, bg = p.bg_alt },
    DiagnosticFloatingInfo = { fg = p.blue, bg = p.bg_alt },
    DiagnosticFloatingHint = { fg = p.comment, bg = p.bg_alt },
    DiagnosticFloatingOk = { fg = p.green, bg = p.bg_alt },
    DiagnosticSignError = { fg = p.red },
    DiagnosticSignWarn = { fg = p.orange },
    DiagnosticSignInfo = { fg = p.blue },
    DiagnosticSignHint = { fg = p.comment },
    DiagnosticSignOk = { fg = p.green },
    DiagnosticDeprecated = { strikethrough = true, sp = p.comment },
    DiagnosticUnnecessary = { fg = p.comment },
  }
end

return M
