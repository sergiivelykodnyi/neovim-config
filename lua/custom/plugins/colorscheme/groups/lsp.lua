-- LSP semantic tokens (:help lsp-semantic-highlight) and diagnostics.
-- VSCode maps each semantic token to a TextMate scope; the colors follow that.
local M = {}

---@param p table palette
---@return table<string, vim.api.keyset.highlight>
function M.get(p)
  return {
    -- Semantic token types
    ['@lsp.type.class'] = { fg = p.yellow },
    ['@lsp.type.comment'] = { fg = p.comment },
    ['@lsp.type.decorator'] = { fg = p.blue },
    ['@lsp.type.enum'] = { fg = p.yellow },
    ['@lsp.type.enumMember'] = { fg = p.cyan }, -- semanticTokenColors.enumMember
    ['@lsp.type.event'] = { fg = p.red },
    ['@lsp.type.function'] = { fg = p.blue },
    ['@lsp.type.interface'] = { fg = p.yellow },
    ['@lsp.type.keyword'] = { fg = p.purple },
    ['@lsp.type.macro'] = { fg = p.orange }, -- semanticTokenColors.macro
    ['@lsp.type.method'] = { fg = p.blue },
    ['@lsp.type.member'] = { fg = p.blue }, -- ts_ls: Math.max, console.log
    ['@lsp.type.modifier'] = { fg = p.purple },
    ['@lsp.type.namespace'] = { fg = p.yellow },
    ['@lsp.type.number'] = { fg = p.orange },
    ['@lsp.type.operator'] = { fg = p.cyan },
    ['@lsp.type.parameter'] = { fg = p.red },
    ['@lsp.type.property'] = { fg = p.red },
    ['@lsp.type.regexp'] = { fg = p.cyan },
    ['@lsp.type.string'] = { fg = p.green },
    ['@lsp.type.struct'] = { fg = p.yellow },
    ['@lsp.type.type'] = { fg = p.yellow },
    ['@lsp.type.typeParameter'] = { fg = p.yellow },
    -- Plain variables keep the tree-sitter color: VSCode shows SCREAMING_CASE consts yellow
    -- and local consts red, which tree-sitter already distinguishes.
    ['@lsp.type.variable'] = {},

    -- Modifiers. Neovim gives these a higher priority than the type groups.
    ['@lsp.typemod.variable.defaultLibrary'] = { fg = p.yellow }, -- Math, console, string: semanticTokenColors variable.defaultLibrary
    ['@lsp.typemod.variable.global'] = { fg = p.yellow }, -- lua-language-server marks vim and self as global; VSCode shows them yellow
    ['@lsp.typemod.function.defaultLibrary'] = { fg = p.cyan }, -- pcall, print: support.function
    ['@lsp.typemod.class.defaultLibrary'] = { fg = p.yellow },
    ['@lsp.typemod.type.defaultLibrary'] = { fg = p.yellow },

    -- Diagnostics
    DiagnosticError = { fg = p.diag_error },
    DiagnosticWarn = { fg = p.diag_warn },
    DiagnosticInfo = { fg = p.diag_info },
    DiagnosticHint = { fg = p.diag_hint },
    DiagnosticOk = { fg = p.green },
    DiagnosticVirtualTextError = { fg = p.diag_error },
    DiagnosticVirtualTextWarn = { fg = p.diag_warn },
    DiagnosticVirtualTextInfo = { fg = p.diag_info },
    DiagnosticVirtualTextHint = { fg = p.diag_hint },
    DiagnosticVirtualTextOk = { fg = p.green },
    DiagnosticUnderlineError = { sp = p.diag_error, undercurl = true },
    DiagnosticUnderlineWarn = { sp = p.diag_warn, undercurl = true },
    DiagnosticUnderlineInfo = { sp = p.diag_info, undercurl = true },
    DiagnosticUnderlineHint = { sp = p.diag_hint, undercurl = true },
    DiagnosticUnderlineOk = { sp = p.green, undercurl = true },
    DiagnosticFloatingError = { fg = p.diag_error, bg = p.bg_float },
    DiagnosticFloatingWarn = { fg = p.diag_warn, bg = p.bg_float },
    DiagnosticFloatingInfo = { fg = p.diag_info, bg = p.bg_float },
    DiagnosticFloatingHint = { fg = p.diag_hint, bg = p.bg_float },
    DiagnosticFloatingOk = { fg = p.green, bg = p.bg_float },
    DiagnosticSignError = { fg = p.diag_error },
    DiagnosticSignWarn = { fg = p.diag_warn },
    DiagnosticSignInfo = { fg = p.diag_info },
    DiagnosticSignHint = { fg = p.diag_hint },
    DiagnosticSignOk = { fg = p.green },
    DiagnosticDeprecated = { sp = p.comment, strikethrough = true },
    DiagnosticUnnecessary = { fg = p.comment },

    -- LSP UI
    LspReferenceText = { bg = p.word_highlight },
    LspReferenceRead = { bg = p.word_highlight },
    LspReferenceWrite = { bg = p.word_highlight },
    LspReferenceTarget = { bg = p.word_highlight },
    LspInlayHint = { fg = p.fg, bg = p.bg_line }, -- editorInlayHint.foreground / background
    LspCodeLens = { fg = p.comment },
    LspCodeLensSeparator = { fg = p.comment },
    LspSignatureActiveParameter = { bg = p.word_highlight },
  }
end

return M
