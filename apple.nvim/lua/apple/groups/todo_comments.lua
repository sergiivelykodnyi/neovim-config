-- todo-comments.nvim: TODO / FIX / NOTE keywords in comments.
-- The plugin also defines these groups from its `colors` option. Our values
-- are a fallback for the default keywords and match the diagnostic colors.
local M = {}

M.detect = 'todo-comments'

---@param p table palette
---@param _ table options (unused here)
function M.get(p, _)
  local colors = {
    FIX = p.red,
    TODO = p.blue,
    HACK = p.orange,
    WARN = p.orange,
    PERF = p.purple,
    NOTE = p.comment,
    TEST = p.green,
  }
  local groups = {}
  for keyword, color in pairs(colors) do
    groups['TodoBg' .. keyword] = { fg = p.bg, bg = color, bold = true }
    groups['TodoFg' .. keyword] = { fg = color }
    groups['TodoSign' .. keyword] = { fg = color }
  end
  return groups
end

return M
