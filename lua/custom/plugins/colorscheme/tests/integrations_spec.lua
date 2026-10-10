local t = require 'helpers'
local palette = require 'custom.plugins.colorscheme.palette'
local M = require 'custom.plugins.colorscheme'

local function is_color(value) return value == 'NONE' or (type(value) == 'string' and value:match '^#%x%x%x%x%x%x$' ~= nil) end

t.test('the integration list has every expected plugin', function()
  local expected = { 'telescope', 'blink', 'gitsigns', 'which_key', 'todo_comments', 'mini', 'fidget', 'mason' }
  vim.list_extend(expected, { 'indent_blankline', 'neo_tree', 'dap', 'rainbow_delimiters' })
  t.eq(expected, M.integrations, 'integrations')
end)

for _, name in ipairs(M.integrations) do
  t.test('groups/' .. name .. ' exports detect and uses only palette colors', function()
    local mod = require('custom.plugins.colorscheme.groups.' .. name)
    t.ok(type(mod.detect) == 'string' or type(mod.detect) == 'table', 'detect')
    local groups = mod.get(t.strict(palette))
    t.ok(type(groups) == 'table' and next(groups) ~= nil, 'returns a non-empty table')
    for group, def in pairs(groups) do
      for _, key in ipairs { 'fg', 'bg', 'sp' } do
        if def[key] ~= nil then t.ok(is_color(def[key]), ('%s.%s = %s'):format(group, key, tostring(def[key]))) end
      end
      t.ok(not def.bold, group .. ' is not bold')
      t.ok(not def.italic, group .. ' is not italic')
    end
  end)
end

t.test('rainbow_delimiters maps the three VSCode bracket levels', function()
  local g = require('custom.plugins.colorscheme.groups.rainbow_delimiters').get(t.strict(palette))
  t.eq({ fg = palette.orange }, g.RainbowDelimiterOrange, 'level 1')
  t.eq({ fg = palette.purple }, g.RainbowDelimiterViolet, 'level 2')
  t.eq({ fg = palette.cyan }, g.RainbowDelimiterCyan, 'level 3')
end)

t.test('integration detect names match the real plugin modules', function()
  local expected = {
    telescope = 'telescope',
    blink = 'blink.cmp',
    gitsigns = 'gitsigns',
    which_key = 'which-key',
    todo_comments = 'todo-comments',
    mini = { 'mini.statusline', 'mini.icons', 'mini.ai', 'mini.surround' },
    fidget = 'fidget',
    mason = 'mason',
    indent_blankline = 'ibl',
    neo_tree = 'neo-tree',
    dap = { 'dap', 'dapui' },
    rainbow_delimiters = 'rainbow-delimiters',
  }
  for name, detect in pairs(expected) do
    t.eq(detect, require('custom.plugins.colorscheme.groups.' .. name).detect, name .. '.detect')
  end
end)
