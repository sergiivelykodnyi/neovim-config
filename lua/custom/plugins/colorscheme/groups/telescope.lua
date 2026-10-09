-- telescope.nvim. Mirrors the VSCode quick-open widget: editorWidget background, suggest border.
local M = {}

M.detect = 'telescope'

---@param p table palette
---@return table<string, vim.api.keyset.highlight>
function M.get(p)
  return {
    TelescopeNormal = { fg = p.fg, bg = p.bg_float },
    TelescopeBorder = { fg = p.border, bg = p.bg_float },
    TelescopeTitle = { fg = p.blue, bg = p.bg_float },

    TelescopePromptNormal = { fg = p.fg, bg = p.bg_input },
    TelescopePromptBorder = { fg = p.border, bg = p.bg_input },
    TelescopePromptTitle = { fg = p.blue, bg = p.bg_input },
    TelescopePromptPrefix = { fg = p.blue, bg = p.bg_input },
    TelescopePromptCounter = { fg = p.comment, bg = p.bg_input },

    TelescopeResultsNormal = { fg = p.fg, bg = p.bg_float },
    TelescopeResultsBorder = { fg = p.border, bg = p.bg_float },
    TelescopeResultsTitle = { fg = p.blue, bg = p.bg_float },
    TelescopeResultsComment = { fg = p.comment },
    TelescopeResultsLineNr = { fg = p.line_nr },

    TelescopePreviewNormal = { fg = p.fg, bg = p.bg_float },
    TelescopePreviewBorder = { fg = p.border, bg = p.bg_float },
    TelescopePreviewTitle = { fg = p.blue, bg = p.bg_float },
    TelescopePreviewLine = { bg = p.bg_line },
    TelescopePreviewMatch = { bg = p.search },

    TelescopeSelection = { bg = p.bg_select },
    TelescopeSelectionCaret = { fg = p.blue, bg = p.bg_select },
    TelescopeMultiSelection = { fg = p.list_fg, bg = p.bg_focus },
    TelescopeMultiIcon = { fg = p.blue },
    TelescopeMatching = { fg = p.blue },

    TelescopeResultsDiffAdd = { fg = p.green },
    TelescopeResultsDiffChange = { fg = p.yellow },
    TelescopeResultsDiffDelete = { fg = p.red },
    TelescopeResultsDiffUntracked = { fg = p.comment },
  }
end

return M
