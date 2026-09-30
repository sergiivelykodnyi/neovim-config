-- Highlight groups for the built-in LSP client: semantic tokens, references, inlay hints.
local M = {}

---@param p table palette
---@param _ table options (unused here)
function M.get(p, _)
  return {
    -- Semantic tokens link to the treesitter captures with the same meaning.
    ['@lsp.type.class'] = { link = '@type' },
    ['@lsp.type.comment'] = { link = '@comment' },
    ['@lsp.type.decorator'] = { link = '@attribute' },
    ['@lsp.type.enum'] = { link = '@type' },
    ['@lsp.type.enumMember'] = { link = '@constant' },
    ['@lsp.type.event'] = { link = '@type' },
    ['@lsp.type.function'] = { link = '@function' },
    ['@lsp.type.interface'] = { link = '@type' },
    ['@lsp.type.keyword'] = { link = '@keyword' },
    ['@lsp.type.macro'] = { link = '@function.macro' },
    ['@lsp.type.method'] = { link = '@function.method' },
    ['@lsp.type.modifier'] = { link = '@keyword.modifier' },
    ['@lsp.type.namespace'] = { link = '@module' },
    ['@lsp.type.number'] = { link = '@number' },
    ['@lsp.type.operator'] = { link = '@operator' },
    ['@lsp.type.parameter'] = { link = '@variable.parameter' },
    ['@lsp.type.property'] = { link = '@property' },
    ['@lsp.type.regexp'] = { link = '@string.regexp' },
    ['@lsp.type.string'] = { link = '@string' },
    ['@lsp.type.struct'] = { link = '@type' },
    ['@lsp.type.type'] = { link = '@type' },
    ['@lsp.type.typeParameter'] = { link = '@type' },
    ['@lsp.type.variable'] = { link = '@variable' },
    ['@lsp.mod.deprecated'] = { strikethrough = true },
    ['@lsp.typemod.variable.readonly'] = { link = '@constant' },
    ['@lsp.typemod.variable.defaultLibrary'] = { link = '@variable.builtin' },
    ['@lsp.typemod.function.defaultLibrary'] = { link = '@function.builtin' },

    -- References and hints
    LspReferenceText = { bg = p.bg_alt },
    LspReferenceRead = { bg = p.bg_alt },
    LspReferenceWrite = { bg = p.bg_alt, underline = true },
    LspReferenceTarget = { bg = p.bg_alt },
    LspInlayHint = { fg = p.comment, bg = p.bg_alt },
    LspCodeLens = { fg = p.comment },
    LspCodeLensSeparator = { fg = p.border },
    LspSignatureActiveParameter = { bg = p.border, bold = true },
  }
end

return M
