-- indent-blankline.nvim (module name ibl). Guides use editorIndentGuide colors.
local M = {}

M.detect = 'ibl'

---@param p table palette
---@return table<string, vim.api.keyset.highlight>
function M.get(p)
  return {
    IblIndent = { fg = p.guide },
    IblWhitespace = { fg = p.whitespace },
    IblScope = { fg = p.indent_active },
  }
end

return M
