-- gitsigns.nvim: signs, line highlights, inline word diff, blame.
local util = require 'apple.util'

local M = {}

M.detect = 'gitsigns'

---@param p table palette
---@param _ table options (unused here)
function M.get(p, _)
  -- Staged signs are a dimmed version of the normal signs.
  local staged_add = util.mix(p.green, p.bg, 0.6)
  local staged_change = util.mix(p.blue, p.bg, 0.6)
  local staged_delete = util.mix(p.red, p.bg, 0.6)
  -- Inline word diff is a stronger version of the line background.
  local inline_add = util.mix(p.diff_add, p.bg, 0.35)
  local inline_change = util.mix(p.diff_change, p.bg, 0.35)
  local inline_delete = util.mix(p.diff_delete, p.bg, 0.35)

  return {
    GitSignsAdd = { fg = p.green },
    GitSignsChange = { fg = p.blue },
    GitSignsDelete = { fg = p.red },
    GitSignsTopdelete = { fg = p.red },
    GitSignsChangedelete = { fg = p.blue },
    GitSignsUntracked = { fg = p.orange },
    GitSignsAddNr = { fg = p.green },
    GitSignsChangeNr = { fg = p.blue },
    GitSignsDeleteNr = { fg = p.red },
    GitSignsAddLn = { bg = p.diff_add_bg },
    GitSignsChangeLn = { bg = p.diff_change_bg },
    GitSignsDeleteVirtLn = { bg = p.diff_delete_bg },
    GitSignsAddInline = { bg = inline_add },
    GitSignsChangeInline = { bg = inline_change },
    GitSignsDeleteInline = { bg = inline_delete },
    GitSignsAddPreview = { bg = p.diff_add_bg },
    GitSignsDeletePreview = { bg = p.diff_delete_bg },
    GitSignsStagedAdd = { fg = staged_add },
    GitSignsStagedChange = { fg = staged_change },
    GitSignsStagedDelete = { fg = staged_delete },
    GitSignsStagedTopdelete = { fg = staged_delete },
    GitSignsStagedChangedelete = { fg = staged_change },
    GitSignsCurrentLineBlame = { fg = p.comment },
  }
end

return M
