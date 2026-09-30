local t = require 'helpers'
local util = require 'apple.util'
local palette = require 'apple.palette'
local hig = require 'hig'

local function is_hex(s)
  return type(s) == 'string' and s:match '^#%x%x%x%x%x%x$' ~= nil
end

for _, mode in ipairs { 'dark', 'light' } do
  local p = palette[mode]
  local hc = mode == 'dark' and 'hc_dark' or 'hc_light'

  t.test(mode .. ': every color is #RRGGBB (uppercase) or NONE', function()
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

  t.test(mode .. ': base grays are HIG system grays', function()
    t.eq(hig.gray6[mode], p.bg, 'bg')
    t.eq(hig.gray5[mode], p.bg_alt, 'bg_alt')
    t.eq(hig.gray3[mode], p.border, 'border')
    t.eq(hig.gray2[mode], p.line_nr, 'line_nr')
  end)

  t.test(mode .. ': text colors are HIG increased contrast colors', function()
    for _, name in ipairs { 'red', 'orange', 'yellow', 'green', 'teal', 'blue', 'purple', 'pink' } do
      t.eq(hig[name][hc], p[name], name)
    end
  end)

  t.test(mode .. ': diff base colors are HIG default colors', function()
    t.eq(hig.green[mode], p.diff_add, 'diff_add')
    t.eq(hig.blue[mode], p.diff_change, 'diff_change')
    t.eq(hig.red[mode], p.diff_delete, 'diff_delete')
  end)

  t.test(mode .. ': derived diff backgrounds come from util.mix', function()
    t.eq(util.mix(p.diff_add, p.bg, 0.15), p.diff_add_bg, 'diff_add_bg')
    t.eq(util.mix(p.diff_change, p.bg, 0.15), p.diff_change_bg, 'diff_change_bg')
    t.eq(util.mix(p.diff_delete, p.bg, 0.15), p.diff_delete_bg, 'diff_delete_bg')
    t.eq(util.mix(p.diff_change, p.bg, 0.3), p.diff_text_bg, 'diff_text_bg')
  end)

  t.test(mode .. ': text is readable', function()
    t.min_contrast(p.fg, p.bg, 7.0, 'fg on bg')
    t.min_contrast(p.fg, p.bg_alt, 7.0, 'fg on bg_alt')
    t.min_contrast(p.comment, p.bg, 3.0, 'comment on bg')
    t.min_contrast(p.comment, p.bg_alt, 3.0, 'comment on bg_alt')
    for _, name in ipairs { 'red', 'orange', 'yellow', 'green', 'teal', 'blue', 'purple', 'pink' } do
      t.min_contrast(p[name], p.bg, 3.0, name .. ' on bg')
    end
    t.min_contrast(p.search_fg, p.search, 4.5, 'search')
    t.min_contrast(p.search_fg, p.cur_search, 4.5, 'cur_search')
    t.min_contrast(p.selection_fg, p.selection, 4.5, 'selection')
  end)
end
