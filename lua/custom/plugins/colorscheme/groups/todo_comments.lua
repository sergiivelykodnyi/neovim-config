-- todo-comments.nvim. The VSCode theme has no TODO colors; these use the syntax colors by meaning.
local M = {}

M.detect = 'todo-comments'

---@param p table palette
---@return table<string, vim.api.keyset.highlight>
function M.get(p)
  local keywords = {
    TODO = p.blue,
    NOTE = p.cyan,
    WARN = p.orange,
    FIX = p.red,
    PERF = p.purple,
    HACK = p.orange,
    TEST = p.green,
  }
  local groups = {}
  for keyword, color in pairs(keywords) do
    groups['TodoBg' .. keyword] = { fg = p.bg, bg = color }
    groups['TodoFg' .. keyword] = { fg = color }
    groups['TodoSign' .. keyword] = { fg = color }
  end
  return groups
end

return M
