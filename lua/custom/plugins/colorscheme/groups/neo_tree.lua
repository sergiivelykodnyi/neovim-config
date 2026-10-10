-- neo-tree.nvim. Mirrors the VSCode side bar: same background as the editor, sideBar.border.
local M = {}

M.detect = 'neo-tree'

---@param p table palette
---@return table<string, vim.api.keyset.highlight>
function M.get(p)
  return {
    NeoTreeNormal = { fg = p.fg, bg = p.bg },
    NeoTreeNormalNC = { fg = p.fg, bg = p.bg },
    NeoTreeEndOfBuffer = { fg = p.bg, bg = p.bg },
    NeoTreeWinSeparator = { fg = p.border_sidebar, bg = p.bg },
    NeoTreeVertSplit = { fg = p.border_sidebar, bg = p.bg },
    NeoTreeCursorLine = { bg = p.bg_select },
    NeoTreeStatusLine = { fg = p.status_fg, bg = p.bg },
    NeoTreeStatusLineNC = { fg = p.inactive_fg, bg = p.bg },
    NeoTreeSignColumn = { bg = p.bg },

    NeoTreeRootName = { fg = p.fg },
    NeoTreeDirectoryName = { fg = p.fg },
    NeoTreeDirectoryIcon = { fg = p.blue },
    NeoTreeFileName = { fg = p.fg },
    NeoTreeFileNameOpened = { fg = p.list_fg },
    NeoTreeFileIcon = { fg = p.fg },
    NeoTreeSymbolicLinkTarget = { fg = p.cyan },
    NeoTreeIndentMarker = { fg = p.whitespace },
    NeoTreeExpander = { fg = p.comment },
    NeoTreeDotfile = { fg = p.comment },
    NeoTreeHiddenByName = { fg = p.comment },
    NeoTreeMessage = { fg = p.comment },
    NeoTreeModified = { fg = p.orange },
    NeoTreeDimText = { fg = p.comment },

    -- gitDecoration colors
    NeoTreeGitAdded = { fg = p.green },
    NeoTreeGitModified = { fg = p.yellow },
    NeoTreeGitDeleted = { fg = p.red },
    NeoTreeGitRenamed = { fg = p.yellow },
    NeoTreeGitUntracked = { fg = p.green },
    NeoTreeGitIgnored = { fg = p.comment },
    NeoTreeGitConflict = { fg = p.red },
    NeoTreeGitStaged = { fg = p.green },
    NeoTreeGitUnstaged = { fg = p.yellow },

    NeoTreeTitleBar = { fg = p.fg, bg = p.bg_tab },
    NeoTreeFloatBorder = { fg = p.border, bg = p.bg_float },
    NeoTreeFloatTitle = { fg = p.blue, bg = p.bg_float },
    NeoTreeFloatNormal = { fg = p.fg, bg = p.bg_float },
    NeoTreeTabActive = { fg = p.tab_fg, bg = p.bg_tab },
    NeoTreeTabInactive = { fg = p.inactive_fg, bg = p.bg },
    NeoTreeTabSeparatorActive = { fg = p.bg_tab, bg = p.bg_tab },
    NeoTreeTabSeparatorInactive = { fg = p.bg, bg = p.bg },
  }
end

return M
