-- gitsigns.nvim. Signs use the VSCode editorGutter colors.
local M = {}

M.detect = 'gitsigns'

---@param p table palette
---@return table<string, vim.api.keyset.highlight>
function M.get(p)
  return {
    GitSignsAdd = { fg = p.git_add },
    GitSignsChange = { fg = p.git_change },
    GitSignsDelete = { fg = p.git_delete },
    GitSignsChangedelete = { fg = p.git_change },
    GitSignsTopdelete = { fg = p.git_delete },
    GitSignsUntracked = { fg = p.git_add },

    GitSignsAddNr = { fg = p.git_add },
    GitSignsChangeNr = { fg = p.git_change },
    GitSignsDeleteNr = { fg = p.git_delete },
    GitSignsAddLn = { bg = p.diff_add_bg },
    GitSignsChangeLn = { bg = p.diff_change_bg },
    GitSignsDeleteLn = { bg = p.diff_delete_bg },

    GitSignsStagedAdd = { fg = p.git_add },
    GitSignsStagedChange = { fg = p.git_change },
    GitSignsStagedDelete = { fg = p.git_delete },
    GitSignsStagedChangedelete = { fg = p.git_change },
    GitSignsStagedTopdelete = { fg = p.git_delete },

    GitSignsAddInline = { bg = p.diff_add_bg },
    GitSignsChangeInline = { bg = p.diff_text_bg },
    GitSignsDeleteInline = { bg = p.diff_delete_bg },
    GitSignsAddPreview = { bg = p.diff_add_bg },
    GitSignsDeletePreview = { bg = p.diff_delete_bg },
    GitSignsCurrentLineBlame = { fg = p.comment },
  }
end

return M
