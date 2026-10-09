local t = require 'helpers'
local p = require 'custom.plugins.colorscheme.palette'

local function is_hex(value) return type(value) == 'string' and value:match '^#%x%x%x%x%x%x$' ~= nil and value == value:lower() end

t.test('every palette color is lowercase #rrggbb', function()
  for name, value in pairs(p) do
    if name == 'terminal' then
      t.eq(16, #value, 'terminal has 16 colors')
      for i, color in ipairs(value) do
        t.ok(is_hex(color), ('terminal[%d] = %s'):format(i, tostring(color)))
      end
    elseif name == 'none' then
      t.eq('NONE', value, 'none')
    else
      t.ok(is_hex(value), ('%s = %s'):format(name, tostring(value)))
    end
  end
end)

t.test('key colors match the VSCode theme', function()
  t.eq('#16191d', p.bg, 'editor.background')
  t.eq('#abb2bf', p.fg, 'editor.foreground')
  t.eq('#528bff', p.cursor, 'editorCursor.foreground')
  t.eq('#667187', p.line_nr, 'editorLineNumber.foreground')
  t.eq('#2c313c', p.bg_line, 'editor.lineHighlightBackground')
  t.eq('#343c4b', p.selection, 'editor.selectionBackground blended')
end)

t.test('terminal colors equal the Ghostty one-dark theme', function()
  local ghostty = { '#3f4451', '#e05561', '#8cc265', '#d18f52', '#4aa5f0', '#c162de', '#42b3c2', '#d7dae0' }
  vim.list_extend(ghostty, { '#4f5666', '#ff616e', '#a5e075', '#f0a45d', '#4dc4ff', '#de73ff', '#4cd1e0', '#e6e6e6' })
  t.eq(ghostty, p.terminal, 'terminal')
end)
