-- rainbow-delimiters.nvim. VSCode editorBracketHighlight.foreground1..3 are
-- orange, purple and cyan; the plugin config picks those three groups. The
-- other groups exist so every default name of the plugin has a color.
local M = {}

M.detect = 'rainbow-delimiters'

---@param p table palette
---@return table<string, vim.api.keyset.highlight>
function M.get(p)
  return {
    RainbowDelimiterOrange = { fg = p.orange },
    RainbowDelimiterViolet = { fg = p.purple },
    RainbowDelimiterCyan = { fg = p.cyan },
    RainbowDelimiterRed = { fg = p.red },
    RainbowDelimiterYellow = { fg = p.yellow },
    RainbowDelimiterBlue = { fg = p.blue },
    RainbowDelimiterGreen = { fg = p.green },
  }
end

return M
