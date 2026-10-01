-- Apple colors for the "apple" colorscheme.
-- Every color is an Apple HIG system color:
-- https://developer.apple.com/design/human-interface-guidelines/color
-- Four flavors: dark, light, dark_contrast, light_contrast.
-- The same values are used by the apple-* Ghostty themes.
local mix = require('apple.util').mix

local M = {}

-- Apple system colors (June 2025 values).
-- light / dark: default values. hc_light / hc_dark: increased contrast values.
local apple = {
  red = { light = '#FF383C', dark = '#FF4245', hc_light = '#E9152D', hc_dark = '#FF6165' },
  orange = { light = '#FF8D28', dark = '#FF9230', hc_light = '#C55300', hc_dark = '#FFA056' },
  yellow = { light = '#FFCC00', dark = '#FFD600', hc_light = '#A16A00', hc_dark = '#FEDF43' },
  green = { light = '#34C759', dark = '#30D158', hc_light = '#008932', hc_dark = '#4AD968' },
  teal = { light = '#00C3D0', dark = '#00D2E0', hc_light = '#008198', hc_dark = '#3BDDEC' },
  cyan = { light = '#00C0E8', dark = '#3CD3FE', hc_light = '#007EAE', hc_dark = '#6DD9FF' },
  blue = { light = '#0088FF', dark = '#0091FF', hc_light = '#1E6EF4', hc_dark = '#5CB8FF' },
  indigo = { light = '#6155F5', dark = '#6D7CFF', hc_light = '#564ADE', hc_dark = '#A7AAFF' },
  purple = { light = '#CB30E0', dark = '#DB34F2', hc_light = '#B02FC2', hc_dark = '#EA8DFF' },
  pink = { light = '#FF2D55', dark = '#FF375F', hc_light = '#E7124D', hc_dark = '#FF8AC4' },
  gray = { light = '#8E8E93', dark = '#8E8E93', hc_light = '#6C6C70', hc_dark = '#AEAEB2' },
  gray2 = { light = '#AEAEB2', dark = '#636366', hc_light = '#8E8E93', hc_dark = '#7C7C80' },
  gray3 = { light = '#C7C7CC', dark = '#48484A', hc_light = '#AEAEB2', hc_dark = '#545456' },
  gray5 = { light = '#E5E5EA', dark = '#2C2C2E', hc_light = '#D8D8DC', hc_dark = '#363638' },
  gray6 = { light = '#F2F2F7', dark = '#1C1C1E', hc_light = '#EBEBF0', hc_dark = '#242426' },
}

-- Terminal colors 0, 7, 8 and 15 (black and white). The same in both contrasts.
local black_white = {
  dark = { '#F2F2F7', '#2C2C2E', '#EBEBF0', '#252526' },
  light = { '#252526', '#E5E5EA', '#2C2C2E', '#EBEBF0' },
}

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

-- Build the palette of one flavor.
---@param mode 'dark'|'light'
---@param contrast 'default'|'increased'
local function build(mode, contrast)
  local hc = 'hc_' .. mode
  -- Column of the Apple table for the colors that follow the contrast
  local column = contrast == 'increased' and hc or mode
  local other = mode == 'dark' and 'light' or 'dark'
  local bw = black_white[mode]
  local function c(name) return apple[name][column] end

  return derive {
    -- Base
    bg = c 'gray6',
    fg = apple.gray6[other], -- the default background of the other mode
    cursor = c 'indigo',
    selection = apple.indigo.hc_dark,
    selection_fg = apple.gray6.dark,

    -- Grays (Apple system grays)
    bg_alt = c 'gray5', -- cursor line, popup menu, status line
    border = c 'gray3',
    line_nr = c 'gray2',
    comment = c 'gray',

    -- Text colors
    red = c 'red',
    orange = c 'orange',
    yellow = c 'yellow',
    green = c 'green',
    teal = c 'teal',
    blue = c 'blue',
    purple = c 'purple',
    pink = c 'pink',

    -- Search backgrounds (Apple default yellow and orange)
    search = apple.yellow[mode],
    cur_search = apple.orange[mode],
    search_fg = apple.gray6.dark,

    -- Diff base colors (Apple default green, blue and red)
    diff_add = apple.green[mode],
    diff_change = apple.blue[mode],
    diff_delete = apple.red[mode],

    -- Terminal colors 0-15. Bright colors (9-14) are always increased contrast.
    terminal = {
      bw[1],
      c 'red',
      c 'green',
      c 'yellow',
      c 'blue',
      c 'purple',
      c 'cyan',
      bw[2],
      bw[3],
      apple.red[hc],
      apple.green[hc],
      apple.yellow[hc],
      apple.blue[hc],
      apple.purple[hc],
      apple.cyan[hc],
      bw[4],
    },
  }
end

M.dark = build('dark', 'default')
M.light = build('light', 'default')
M.dark_contrast = build('dark', 'increased')
M.light_contrast = build('light', 'increased')

-- The palette for a mode and a contrast.
-- Unknown values mean 'dark' and 'default'.
---@param mode 'dark'|'light'
---@param contrast? 'default'|'increased'
function M.get(mode, contrast)
  local name = mode == 'light' and 'light' or 'dark'
  if contrast == 'increased' then name = name .. '_contrast' end
  return M[name]
end

return M
