local t = require 'helpers'
local util = require 'apple.util'
local palette = require 'apple.palette'
local hig = require 'hig'

local function is_hex(s) return type(s) == 'string' and s:match '^#%x%x%x%x%x%x$' ~= nil end

-- column: the hig.lua column for colors that follow the contrast.
local flavors = {
  { name = 'dark', mode = 'dark', column = 'dark' },
  { name = 'light', mode = 'light', column = 'light' },
  { name = 'dark_contrast', mode = 'dark', column = 'hc_dark' },
  { name = 'light_contrast', mode = 'light', column = 'hc_light' },
}

-- ANSI slots 0, 7, 8 and 15 (black and white). The same in both contrasts.
local black_white = {
  dark = { [0] = '#F2F2F7', [7] = '#2C2C2E', [8] = '#EBEBF0', [15] = '#252526' },
  light = { [0] = '#252526', [7] = '#E5E5EA', [8] = '#2C2C2E', [15] = '#EBEBF0' },
}

-- ANSI slot of each Apple color. Normal color = slot, bright color = slot + 8.
local slots = { red = 1, green = 2, yellow = 3, blue = 4, purple = 5, cyan = 6 }

local function sorted_keys(tbl)
  local keys = vim.tbl_keys(tbl)
  table.sort(keys)
  return keys
end

t.test('all four flavors have the same keys', function()
  for _, f in ipairs(flavors) do
    t.eq('table', type(palette[f.name]), f.name)
    t.eq(sorted_keys(palette.dark), sorted_keys(palette[f.name]), f.name)
  end
end)

t.test('get() returns the palette for a mode and a contrast', function()
  t.ok(palette.get('dark', 'default') == palette.dark, 'dark default')
  t.ok(palette.get('light', 'default') == palette.light, 'light default')
  t.ok(palette.get('dark', 'increased') == palette.dark_contrast, 'dark increased')
  t.ok(palette.get('light', 'increased') == palette.light_contrast, 'light increased')
end)

t.test('get() treats unknown values as dark and default', function()
  t.ok(palette.get('dark', nil) == palette.dark, 'nil contrast')
  t.ok(palette.get('light', 'high') == palette.light, 'unknown contrast')
  t.ok(palette.get('light', true) == palette.light, 'boolean contrast')
  t.ok(palette.get(nil, 'increased') == palette.dark_contrast, 'nil mode')
end)

for _, f in ipairs(flavors) do
  local p = palette[f.name] or {}
  local mode, column = f.mode, f.column
  local hc = 'hc_' .. mode
  local other = mode == 'dark' and 'light' or 'dark'

  t.test(f.name .. ': every color is #RRGGBB (uppercase) or NONE', function()
    for key, value in pairs(p) do
      if key == 'terminal' then
        t.eq(16, #value, 'terminal has 16 colors')
        for i, c in ipairs(value) do
          t.ok(is_hex(c) and c == c:upper(), ('terminal[%d] = %s'):format(i, tostring(c)))
        end
      elseif key == 'none' then
        t.eq('NONE', value)
      else
        t.ok(is_hex(value) and value == value:upper(), key .. ' = ' .. tostring(value))
      end
    end
  end)

  t.test(f.name .. ': grays are the HIG grays of the flavor', function()
    t.eq(hig.gray6[column], p.bg, 'bg')
    t.eq(hig.gray5[column], p.bg_alt, 'bg_alt')
    t.eq(hig.gray3[column], p.border, 'border')
    t.eq(hig.gray2[column], p.line_nr, 'line_nr')
    t.eq(hig.gray[column], p.comment, 'comment')
  end)

  t.test(f.name .. ': text colors and cursor are the HIG colors of the flavor', function()
    for _, name in ipairs { 'red', 'orange', 'yellow', 'green', 'teal', 'blue', 'purple', 'pink' } do
      t.eq(hig[name][column], p[name], name)
    end
    t.eq(hig.indigo[column], p.cursor, 'cursor')
  end)

  t.test(f.name .. ': fg, selection, search and diff colors do not follow the contrast', function()
    t.eq(hig.gray6[other], p.fg, 'fg')
    t.eq('#A7AAFF', p.selection, 'selection')
    t.eq('#1C1C1E', p.selection_fg, 'selection_fg')
    t.eq(hig.yellow[mode], p.search, 'search')
    t.eq(hig.orange[mode], p.cur_search, 'cur_search')
    t.eq('#1C1C1E', p.search_fg, 'search_fg')
    t.eq(hig.green[mode], p.diff_add, 'diff_add')
    t.eq(hig.blue[mode], p.diff_change, 'diff_change')
    t.eq(hig.red[mode], p.diff_delete, 'diff_delete')
  end)

  t.test(f.name .. ': derived diff backgrounds come from util.mix', function()
    t.eq(util.mix(p.diff_add, p.bg, 0.15), p.diff_add_bg, 'diff_add_bg')
    t.eq(util.mix(p.diff_change, p.bg, 0.15), p.diff_change_bg, 'diff_change_bg')
    t.eq(util.mix(p.diff_delete, p.bg, 0.15), p.diff_delete_bg, 'diff_delete_bg')
    t.eq(util.mix(p.diff_change, p.bg, 0.3), p.diff_text_bg, 'diff_text_bg')
  end)

  t.test(f.name .. ': terminal normal colors follow the flavor, bright colors are increased contrast', function()
    for name, slot in pairs(slots) do
      t.eq(hig[name][column], p.terminal[slot + 1], name .. ' (slot ' .. slot .. ')')
      t.eq(hig[name][hc], p.terminal[slot + 9], name .. ' (slot ' .. (slot + 8) .. ')')
    end
  end)

  t.test(f.name .. ': terminal black and white slots keep their values', function()
    for slot, color in pairs(black_white[mode]) do
      t.eq(color, p.terminal[slot + 1], 'slot ' .. slot)
    end
  end)
end
