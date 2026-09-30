-- neo-tree.nvim: file explorer side window.
local M = {}

M.detect = 'neo-tree'

---@param p table palette
---@param _ table options (unused here)
function M.get(p, _)
  return {
    NeoTreeNormal = { fg = p.fg, bg = p.bg_alt },
    NeoTreeNormalNC = { fg = p.fg, bg = p.bg_alt },
    NeoTreeEndOfBuffer = { fg = p.bg_alt, bg = p.bg_alt },
    NeoTreeWinSeparator = { fg = p.border, bg = p.bg_alt },
    NeoTreeCursorLine = { bg = p.border },
    NeoTreeStatusLine = { fg = p.fg, bg = p.bg_alt },
    NeoTreeStatusLineNC = { fg = p.comment, bg = p.bg_alt },
    NeoTreeSignColumn = { bg = p.bg_alt },
    NeoTreeVertSplit = { fg = p.border, bg = p.bg_alt },

    NeoTreeRootName = { fg = p.blue, bold = true },
    NeoTreeDirectoryName = { fg = p.blue },
    NeoTreeDirectoryIcon = { fg = p.blue },
    NeoTreeFileName = { fg = p.fg },
    NeoTreeFileNameOpened = { fg = p.fg, bold = true },
    NeoTreeFileIcon = { fg = p.fg },
    NeoTreeSymbolicLinkTarget = { fg = p.teal },
    NeoTreeIndentMarker = { fg = p.border },
    NeoTreeExpander = { fg = p.line_nr },
    NeoTreeDotfile = { fg = p.comment },
    NeoTreeHiddenByName = { fg = p.comment },
    NeoTreeMessage = { fg = p.comment, italic = true },
    NeoTreeModified = { fg = p.orange },
    NeoTreeDimText = { fg = p.comment },

    NeoTreeGitAdded = { fg = p.green },
    NeoTreeGitModified = { fg = p.blue },
    NeoTreeGitDeleted = { fg = p.red },
    NeoTreeGitRenamed = { fg = p.purple },
    NeoTreeGitUntracked = { fg = p.orange },
    NeoTreeGitIgnored = { fg = p.comment },
    NeoTreeGitConflict = { fg = p.red, bold = true },
    NeoTreeGitStaged = { fg = p.green },
    NeoTreeGitUnstaged = { fg = p.orange },

    NeoTreeTitleBar = { fg = p.bg, bg = p.blue, bold = true },
    NeoTreeFloatBorder = { fg = p.border, bg = p.bg_alt },
    NeoTreeFloatTitle = { fg = p.fg, bg = p.bg_alt, bold = true },
    NeoTreeFloatNormal = { fg = p.fg, bg = p.bg_alt },
    NeoTreeTabActive = { fg = p.fg, bg = p.bg_alt, bold = true },
    NeoTreeTabInactive = { fg = p.comment, bg = p.bg },
    NeoTreeTabSeparatorActive = { fg = p.bg_alt, bg = p.bg_alt },
    NeoTreeTabSeparatorInactive = { fg = p.bg, bg = p.bg },
  }
end

return M
