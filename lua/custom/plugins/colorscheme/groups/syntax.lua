-- Classic Vim syntax groups. See :help group-name.
-- Used for file types without a tree-sitter parser.
local M = {}

---@param p table palette
---@return table<string, vim.api.keyset.highlight>
function M.get(p)
  return {
    Comment = { fg = p.comment },
    SpecialComment = { fg = p.comment },

    Constant = { fg = p.orange },
    String = { fg = p.green },
    Character = { fg = p.green },
    Number = { fg = p.orange },
    Boolean = { fg = p.orange },
    Float = { fg = p.orange },

    Identifier = { fg = p.red },
    Function = { fg = p.blue },

    Statement = { fg = p.purple },
    Conditional = { fg = p.purple },
    Repeat = { fg = p.purple },
    Label = { fg = p.red },
    Operator = { fg = p.cyan },
    Keyword = { fg = p.purple },
    Exception = { fg = p.purple },

    PreProc = { fg = p.purple },
    Include = { fg = p.purple },
    Define = { fg = p.purple },
    Macro = { fg = p.orange },
    PreCondit = { fg = p.purple },

    Type = { fg = p.yellow },
    StorageClass = { fg = p.purple },
    Structure = { fg = p.yellow },
    Typedef = { fg = p.yellow },

    Special = { fg = p.cyan },
    SpecialChar = { fg = p.cyan },
    Tag = { fg = p.red },
    Delimiter = { fg = p.fg },
    Debug = { fg = p.purple },

    Todo = { fg = p.blue },
    Error = { fg = p.error },
  }
end

return M
