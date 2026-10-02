-- Apple colors for the "apple" colorscheme.
-- Every color is an Apple HIG color:
-- https://developer.apple.com/design/human-interface-guidelines/color
-- The same values are used by the apple-dark / apple-light Ghostty themes.
local mix = require('apple.util').mix

local M = {}

-- Add the colors that are computed from other colors.
local function derive(p)
  p.none = 'NONE'
  -- Soft diff backgrounds: a little Apple color on top of the background
  p.diff_add_bg = mix(p.diff_add, p.bg, 0.15)
  p.diff_change_bg = mix(p.diff_change, p.bg, 0.15)
  p.diff_delete_bg = mix(p.diff_delete, p.bg, 0.15)
  p.diff_text_bg = mix(p.diff_change, p.bg, 0.3)
  return p
end

M.dark = derive {
  -- Base
  bg = '#1C1C1E', -- gray 6
  fg = '#F2F2F7',
  cursor = '#6D7CFF', -- indigo
  selection = '#A7AAFF', -- indigo, increased contrast
  selection_fg = '#1C1C1E',

  -- Grays (Apple system grays)
  bg_alt = '#2C2C2E', -- gray 5: cursor line, popup menu, status line
  border = '#48484A', -- gray 3
  line_nr = '#636366', -- gray 2
  comment = '#8E8E93', -- gray

  -- Text colors (Apple increased contrast colors)
  red = '#FF6165',
  orange = '#FFA056',
  yellow = '#FEDF43',
  green = '#4AD968',
  mint = '#54DFCB',
  teal = '#3BDDEC',
  cyan = '#6DD9FF',
  blue = '#5CB8FF',
  purple = '#EA8DFF',
  pink = '#FF8AC4',
  brown = '#DBA679',

  -- Search backgrounds (Apple yellow and orange)
  search = '#FFD600',
  cur_search = '#FF9230',
  search_fg = '#1C1C1E',

  -- Diff base colors (Apple green, blue and red)
  diff_add = '#30D158',
  diff_change = '#0091FF',
  diff_delete = '#FF4245',

  -- Terminal colors 0-15
  terminal = {
    '#F2F2F7',
    '#FF6165',
    '#4AD968',
    '#FEDF43',
    '#5CB8FF',
    '#EA8DFF',
    '#6DD9FF',
    '#2C2C2E',
    '#EBEBF0',
    '#FF4245',
    '#30D158',
    '#FFD600',
    '#0091FF',
    '#DB34F2',
    '#3CD3FE',
    '#252526',
  },
}

M.light = derive {
  -- Base
  bg = '#F2F2F7', -- gray 6
  fg = '#1C1C1E',
  cursor = '#6155F5', -- indigo
  selection = '#A7AAFF',
  selection_fg = '#1C1C1E',

  -- Grays (Apple system grays)
  bg_alt = '#E5E5EA', -- gray 5: cursor line, popup menu, status line
  border = '#C7C7CC', -- gray 3
  line_nr = '#AEAEB2', -- gray 2
  comment = '#6C6C70', -- gray, increased contrast (plain gray is too light here)

  -- Text colors (Apple increased contrast colors)
  red = '#E9152D',
  orange = '#C55300',
  yellow = '#A16A00',
  green = '#008932',
  mint = '#008575',
  teal = '#008198',
  cyan = '#007EAE',
  blue = '#1E6EF4',
  purple = '#B02FC2',
  pink = '#E7124D',
  brown = '#956D51',

  -- Search backgrounds (Apple yellow and orange)
  search = '#FFCC00',
  cur_search = '#FF8D28',
  search_fg = '#1C1C1E',

  -- Diff base colors (Apple green, blue and red)
  diff_add = '#34C759',
  diff_change = '#0088FF',
  diff_delete = '#FF383C',

  -- Terminal colors 0-15
  terminal = {
    '#252526',
    '#E9152D',
    '#008932',
    '#A16A00',
    '#1E6EF4',
    '#B02FC2',
    '#007EAE',
    '#E5E5EA',
    '#2C2C2E',
    '#FF383C',
    '#34C759',
    '#FFCC00',
    '#0088FF',
    '#CB30E0',
    '#00C0E8',
    '#EBEBF0',
  },
}

return M
