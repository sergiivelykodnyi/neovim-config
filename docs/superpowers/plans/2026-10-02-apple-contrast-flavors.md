# Apple Themes: Default and Increased Contrast Flavors Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give the `apple` themes four flavors (default dark, default light, increased contrast dark, increased contrast light) for Neovim, Ghostty and Warp, with default colors as the default.

**Architecture:** In `apple.nvim`, one table of Apple values and one `build(mode, contrast)` function replace the two hand-written palettes; a new `contrast` option picks the column. In `macos-configs`, each flavor is one hand-written Ghostty file and one Warp file, checked by tests against Apple's values. The minimal Neovim config in `macos-configs` is removed.

**Tech Stack:** Lua, Neovim 0.11+ (`nvim --clean -l` as the test runner, no test library), StyLua, Ghostty theme files, Warp YAML themes.

**Spec:** `docs/superpowers/specs/2026-10-02-apple-contrast-flavors-design.md` (in `neovim-config`)

## Global Constraints

- Two repositories. Part A: `/Users/sergii/github/personal/neovim-config`, branch `apple-contrast-flavors` (already exists, holds the spec). Part B: `/Users/sergii/github/personal/macos-configs`, new branch `apple-contrast-flavors`. The parts do not depend on each other.
- Every color is an Apple HIG value (June 2025). The full table is `apple.nvim/tests/hig.lua`. Never invent or adjust a color.
- No contrast or readability rule. Do not add contrast checks. Do not change a color because it is hard to read.
- Default flavors are the default: `contrast = 'default'`, and the file names `apple-dark`, `apple-light`, `apple_dark.yaml`, `apple_light.yaml` hold default colors.
- Any `contrast` value other than `'increased'` is treated as `'default'`.
- Comments in code: simple English, same density as the surrounding code.
- `neovim-config` Lua must pass `stylua --check .` (config in `.stylua.toml`). Run `stylua apple.nvim init.lua` before each commit there.
- `macos-configs` Lua style: `require('x')` with parentheses, 2 spaces, no collapsed `if` (see `tests/nvim/helpers.lua`). There is no StyLua config there.
- `macos-configs` has uncommitted user changes (`ghostty/.config/ghostty/config`, `git/.gitconfig`, `herdr/`, `oh-my-posh/`, `zsh/`, `lazygit/`). Never edit, stage or commit them. Stage files by exact path only. Never use `git add -A`, `git add .` or `git commit -a`.
- Git commits: the message may end with exactly one trailer line, `Written by Claude`. No email address, no `Co-Authored-By`, no session link. A subagent that commits must get this rule in its prompt.
- Do not push and do not open pull requests without asking the user.

## Review Focus

1. `contrast` gets a wrong value (`'high'`, `''`, `true`, `1`): the colorscheme loads with default colors and no error. Pinned in Task A2.
2. The user changes `contrast` with `setup()` and runs `:colorscheme apple` again: the colors switch, and switch back. Pinned in Task A2.
3. `flavor = 'auto'` with `contrast = 'increased'`, and the terminal switches light/dark: the theme stays in the increased contrast column. Pinned in Task A2.
4. A plugin is loaded after `:colorscheme` (the `VimEnter` path, `apply_new_integrations()`): its groups use the increased contrast palette, not the default one. Pinned in Task A2.
5. A theme file is incomplete (a missing ANSI slot, a missing `cursor-color`, a Warp file without `accent`): the test names the file and the key. Pinned in Task B2.

---

## File Structure

**neovim-config**

| File | Change | Responsibility |
|---|---|---|
| `apple.nvim/lua/apple/palette.lua` | rewrite | Apple values, `build()`, four palettes, `get()` |
| `apple.nvim/lua/apple/config.lua` | modify | new `contrast` option |
| `apple.nvim/lua/apple/init.lua` | modify | pick the palette with `get()` |
| `apple.nvim/tests/palette_spec.lua` | rewrite | values of all four flavors |
| `apple.nvim/tests/integrations_spec.lua` | modify | four flavors, no contrast checks |
| `apple.nvim/tests/helpers.lua` | modify | remove contrast helpers |
| `apple.nvim/tests/config_spec.lua` | modify | `contrast` default and merge |
| `apple.nvim/tests/colorscheme_spec.lua` | modify | loading with `contrast` |
| `apple.nvim/README.md` | modify | four flavors, option, palette table |
| `init.lua` | modify | show the `contrast` option in `setup` |

**macos-configs**

| File | Change | Responsibility |
|---|---|---|
| `nvim/` | delete | minimal Neovim config (no longer needed) |
| `tests/nvim/{colorscheme,config,palette}_spec.lua` | delete | tests of that config |
| `tests/nvim/{run,helpers,hig,themes_spec}.lua` | move to `tests/themes/` | theme tests |
| `ghostty/.config/ghostty/themes/apple-dark`, `apple-light` | modify | default flavors |
| `ghostty/.config/ghostty/themes/apple-dark-contrast`, `apple-light-contrast` | create | increased contrast flavors |
| `warp/.warp/themes/apple_dark.yaml`, `apple_light.yaml` | modify | default flavors |
| `warp/.warp/themes/apple_dark_contrast.yaml`, `apple_light_contrast.yaml` | create | increased contrast flavors |
| `README.md` | modify | replace the Neovim section with a themes section |

---

# Part A: apple.nvim (repository `neovim-config`)

Work in `/Users/sergii/github/personal/neovim-config` on branch `apple-contrast-flavors`.

Test command (from the repository root):

```bash
nvim --clean -l apple.nvim/tests/run.lua
```

The last line of the output is `N passed, M failed`. The exit code is 0 only when `M` is 0.

### Task A1: Palette with four flavors

**Files:**
- Modify (rewrite): `apple.nvim/lua/apple/palette.lua`
- Modify (rewrite): `apple.nvim/tests/palette_spec.lua`
- Modify: `apple.nvim/tests/integrations_spec.lua:35-49`, `:132-155`, `:171-176`
- Modify: `apple.nvim/tests/helpers.lua:24-49`

**Interfaces:**
- Consumes: `require('apple.util').mix(fg, bg, amount)` (exists), `apple.nvim/tests/hig.lua` (exists; columns `light`, `dark`, `hc_light`, `hc_dark`).
- Produces: `require('apple.palette')` with four tables `dark`, `light`, `dark_contrast`, `light_contrast` (same keys as today's `dark`), and `get(mode, contrast)`: `mode` is `'dark' | 'light'` (anything else means `'dark'`), `contrast` is `'default' | 'increased'` (anything else means `'default'`); it returns one of the four tables.

- [ ] **Step 1: Check the branch**

```bash
cd /Users/sergii/github/personal/neovim-config && git switch apple-contrast-flavors && git status --short
```

Expected: `Switched to branch` or `Already on`, and a clean tree.

- [ ] **Step 2: Write the failing palette test**

Replace the whole content of `apple.nvim/tests/palette_spec.lua` with:

```lua
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
```

- [ ] **Step 3: Run the tests to see them fail**

Run: `nvim --clean -l apple.nvim/tests/run.lua`

Expected: failures in `palette_spec.lua`, for example `FAIL all four flavors have the same keys` (`dark_contrast: expected "table", got "nil"`), `FAIL get() returns the palette for a mode and a contrast`, and `FAIL dark: text colors and cursor are the HIG colors of the flavor`. The last line shows more than 0 failed.

- [ ] **Step 4: Rewrite the palette**

Replace the whole content of `apple.nvim/lua/apple/palette.lua` with:

```lua
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
```

- [ ] **Step 5: Remove the contrast checks from the integration tests and run them for four flavors**

In `apple.nvim/tests/integrations_spec.lua`, replace this block (the generic loop):

```lua
  for _, mode in ipairs { 'dark', 'light' } do
    t.test(name .. ' (' .. mode .. '): returns valid highlight definitions', function()
      local defs = mod.get(palette[mode], config.defaults)
```

with:

```lua
  for _, flavor in ipairs { 'dark', 'light', 'dark_contrast', 'light_contrast' } do
    t.test(name .. ' (' .. flavor .. '): returns valid highlight definitions', function()
      local defs = mod.get(palette[flavor], config.defaults)
```

Replace the whole mini statusline loop:

```lua
for _, mode in ipairs { 'dark', 'light' } do
  local p = palette[mode]
  t.test('mini (' .. mode .. '): statusline mode blocks use one Apple color and are readable', function()
    local defs = require('apple.groups.mini').get(p, config.defaults)
    local expected = {
      MiniStatuslineModeNormal = p.blue,
      MiniStatuslineModeInsert = p.green,
      MiniStatuslineModeVisual = p.purple,
      MiniStatuslineModeReplace = p.red,
      MiniStatuslineModeCommand = p.orange,
      MiniStatuslineModeOther = p.teal,
    }
    for group, color in pairs(expected) do
      t.eq(color, defs[group].bg, group .. ' bg')
      t.eq(true, defs[group].bold, group .. ' bold')
      -- The mode name is bold, so 3.0 (WCAG for bold text) is enough.
      t.min_contrast(defs[group].fg, defs[group].bg, 3.0, group)
    end
    t.eq(p.bg_alt, defs.MiniStatuslineFilename.bg)
    t.eq(p.border, defs.MiniStatuslineDevinfo.bg)
    t.min_contrast(defs.MiniStatuslineDevinfo.fg, p.border, 4.5, 'Devinfo')
    t.min_contrast(defs.MiniStatuslineInactive.fg, defs.MiniStatuslineInactive.bg, 3.0, 'Inactive')
  end)
end
```

with:

```lua
for _, flavor in ipairs { 'dark', 'light', 'dark_contrast', 'light_contrast' } do
  local p = palette[flavor]
  t.test('mini (' .. flavor .. '): statusline mode blocks use one Apple color', function()
    local defs = require('apple.groups.mini').get(p, config.defaults)
    local expected = {
      MiniStatuslineModeNormal = p.blue,
      MiniStatuslineModeInsert = p.green,
      MiniStatuslineModeVisual = p.purple,
      MiniStatuslineModeReplace = p.red,
      MiniStatuslineModeCommand = p.orange,
      MiniStatuslineModeOther = p.teal,
    }
    for group, color in pairs(expected) do
      t.eq(color, defs[group].bg, group .. ' bg')
      t.eq(true, defs[group].bold, group .. ' bold')
    end
    t.eq(p.bg_alt, defs.MiniStatuslineFilename.bg)
    t.eq(p.border, defs.MiniStatuslineDevinfo.bg)
  end)
end
```

Replace the mason test:

```lua
t.test('mason: header is a blue block with readable text', function()
  local defs = require('apple.groups.mason').get(palette.light, config.defaults)
  t.eq(palette.light.blue, defs.MasonHeader.bg)
  t.min_contrast(defs.MasonHeader.fg, defs.MasonHeader.bg, 3.0, 'MasonHeader')
  t.eq(palette.light.comment, defs.MasonMuted.fg)
end)
```

with:

```lua
t.test('mason: header is a blue block', function()
  local defs = require('apple.groups.mason').get(palette.light, config.defaults)
  t.eq(palette.light.blue, defs.MasonHeader.bg)
  t.eq(palette.light.comment, defs.MasonMuted.fg)
end)
```

- [ ] **Step 6: Remove the contrast helpers**

In `apple.nvim/tests/helpers.lua`, delete this whole block (from the `channel` comment to the end of `min_contrast`, with the empty line after it):

```lua
-- WCAG relative luminance of one color channel (0-255).
local function channel(c)
  c = c / 255
  return c <= 0.03928 and c / 12.92 or ((c + 0.055) / 1.055) ^ 2.4
end

local function luminance(hex)
  local r = tonumber(hex:sub(2, 3), 16)
  local g = tonumber(hex:sub(4, 5), 16)
  local b = tonumber(hex:sub(6, 7), 16)
  return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)
end

-- WCAG contrast ratio between two '#RRGGBB' colors (1 to 21).
function M.contrast(a, b)
  local x, y = luminance(a), luminance(b)
  if x < y then
    x, y = y, x
  end
  return (x + 0.05) / (y + 0.05)
end

function M.min_contrast(fg, bg, min, label)
  local ratio = M.contrast(fg, bg)
  if ratio < min then error(('%s: %s on %s has %.2f:1, needs %.1f:1'):format(label, fg, bg, ratio, min), 2) end
end

```

Then check that nothing uses them:

```bash
grep -rn 'contrast(' apple.nvim/tests
```

Expected: no output.

- [ ] **Step 7: Format and run the tests**

```bash
stylua apple.nvim && stylua --check . && nvim --clean -l apple.nvim/tests/run.lua
```

Expected: no StyLua output, and the last line is `N passed, 0 failed`. If StyLua changed the layout of a table you wrote, keep its layout.

- [ ] **Step 8: Commit**

```bash
git add apple.nvim/lua/apple/palette.lua apple.nvim/tests/palette_spec.lua apple.nvim/tests/integrations_spec.lua apple.nvim/tests/helpers.lua
git commit -m "Build four apple palettes from Apple default and increased contrast colors

Written by Claude"
```

### Task A2: The `contrast` option

**Files:**
- Modify: `apple.nvim/lua/apple/config.lua:4-21`
- Modify: `apple.nvim/lua/apple/init.lua:40`, `:79`
- Modify: `apple.nvim/tests/config_spec.lua`
- Modify: `apple.nvim/tests/colorscheme_spec.lua` (append at the end)

**Interfaces:**
- Consumes: `require('apple.palette').get(mode, contrast)` and the tables `dark`, `light`, `dark_contrast`, `light_contrast` from Task A1.
- Produces: option `contrast` (`'default' | 'increased'`, default `'default'`) in `require('apple.config').defaults` and `.options`. `:colorscheme apple` and `require('apple').apply_new_integrations()` use the palette of that contrast.

- [ ] **Step 1: Write the failing config tests**

In `apple.nvim/tests/config_spec.lua`, in the first test, add one line after `t.eq('auto', config.defaults.flavor)`:

```lua
  t.eq('default', config.defaults.contrast)
```

and rename that test from `'defaults: auto flavor, plain comments, bold keywords'` to `'defaults: auto flavor, default contrast, plain comments, bold keywords'`.

Add this test before the last line of the file (`config.extend()`):

```lua
t.test('extend sets contrast and resets it on the next call', function()
  local o = config.extend { contrast = 'increased' }
  t.eq('increased', o.contrast)
  t.eq('auto', o.flavor, 'flavor keeps its default')
  t.eq('default', config.extend({}).contrast)
end)

```

- [ ] **Step 2: Write the failing colorscheme tests**

Append to the end of `apple.nvim/tests/colorscheme_spec.lua`:

```lua

t.test('contrast = increased loads the increased contrast palette', function()
  require('apple').setup { contrast = 'increased' }
  vim.o.background = 'dark'
  vim.cmd.colorscheme 'apple'
  local p = palette.dark_contrast
  t.eq(p.bg, t.hex(hl('Normal').bg), 'Normal bg')
  t.eq(p.red, t.hex(hl('String').fg), 'String')
  t.eq(p.comment, t.hex(hl('Comment').fg), 'Comment')
  t.eq(p.terminal[2], vim.g.terminal_color_1, 'terminal_color_1')
  config.extend()
end)

t.test('contrast = increased works with a forced light flavor', function()
  require('apple').setup { flavor = 'light', contrast = 'increased' }
  vim.o.background = 'light'
  vim.cmd.colorscheme 'apple'
  t.eq(palette.light_contrast.bg, t.hex(hl('Normal').bg))
  config.extend()
end)

-- Review focus 1: a wrong value means default colors, not an error.
t.test('an unknown contrast value loads the default colors', function()
  vim.o.background = 'dark'
  for _, value in ipairs { 'high', '', true, 1 } do
    require('apple').setup { contrast = value }
    local ok, err = pcall(vim.cmd.colorscheme, 'apple')
    t.ok(ok, tostring(err))
    t.eq(palette.dark.bg, t.hex(hl('Normal').bg), 'contrast = ' .. vim.inspect(value))
  end
  config.extend()
end)

-- Review focus 2: the option can change at runtime, in both directions.
t.test('changing contrast and reloading switches the palette both ways', function()
  config.extend()
  vim.o.background = 'dark'
  vim.cmd.colorscheme 'apple'
  t.eq(palette.dark.bg, t.hex(hl('Normal').bg), 'default first')
  require('apple').setup { contrast = 'increased' }
  vim.cmd.colorscheme 'apple'
  t.eq(palette.dark_contrast.bg, t.hex(hl('Normal').bg), 'then increased')
  require('apple').setup {}
  vim.cmd.colorscheme 'apple'
  t.eq(palette.dark.bg, t.hex(hl('Normal').bg), 'then default again')
end)

-- Review focus 3: auto mode keeps the contrast when the terminal switches.
t.test('auto flavor keeps increased contrast when background changes', function()
  require('apple').setup { contrast = 'increased' }
  vim.o.background = 'dark'
  vim.cmd.colorscheme 'apple'
  vim.o.background = 'light'
  t.eq(palette.light_contrast.bg, t.hex(hl('Normal').bg), 'light')
  vim.o.background = 'dark'
  t.eq(palette.dark_contrast.bg, t.hex(hl('Normal').bg), 'dark')
  config.extend()
end)

-- Review focus 4: plugins that load after :colorscheme get the same palette.
t.test('integrations added after load use the increased contrast palette', function()
  local apple = require 'apple'
  apple.setup { contrast = 'increased', integrations = { telescope = false } }
  vim.o.background = 'dark'
  vim.cmd 'highlight clear'
  vim.cmd.colorscheme 'apple'
  apple.setup { contrast = 'increased', integrations = { telescope = true } }
  t.eq(true, apple.apply_new_integrations())
  t.eq(palette.dark_contrast.bg_alt, t.hex(hl('TelescopeNormal').bg))
  config.extend()
end)

t.test('on_highlights gets the increased contrast palette', function()
  local seen
  require('apple').setup {
    contrast = 'increased',
    on_highlights = function(_, p) seen = p end,
  }
  vim.o.background = 'dark'
  vim.cmd.colorscheme 'apple'
  t.ok(seen == palette.dark_contrast, 'palette passed to on_highlights')
  config.extend()
  vim.cmd.colorscheme 'apple'
end)
```

- [ ] **Step 3: Run the tests to see them fail**

Run: `nvim --clean -l apple.nvim/tests/run.lua`

Expected failures:
- `FAIL defaults: auto flavor, default contrast, plain comments, bold keywords` (`expected "default", got nil`)
- `FAIL contrast = increased loads the increased contrast palette` (`Normal bg: expected "#242426", got "#1C1C1E"`)
- `FAIL contrast = increased works with a forced light flavor`
- `FAIL changing contrast and reloading switches the palette both ways`
- `FAIL auto flavor keeps increased contrast when background changes`
- `FAIL integrations added after load use the increased contrast palette`
- `FAIL on_highlights gets the increased contrast palette`

`an unknown contrast value loads the default colors` and `extend sets contrast and resets it on the next call` pass already. That is fine: they guard the fallback and the merge.

- [ ] **Step 4: Add the option**

In `apple.nvim/lua/apple/config.lua`, replace:

```lua
---@class AppleOptions
---@field flavor 'auto'|'dark'|'light' 'auto' follows 'background'
```

with:

```lua
---@class AppleOptions
---@field flavor 'auto'|'dark'|'light' 'auto' follows 'background'
---@field contrast 'default'|'increased' which Apple colors to use
```

and replace:

```lua
M.defaults = {
  flavor = 'auto',
```

with:

```lua
M.defaults = {
  flavor = 'auto',
  contrast = 'default',
```

- [ ] **Step 5: Use the option when loading**

In `apple.nvim/lua/apple/init.lua`, in `do_load()`, replace:

```lua
  local palette = require('apple.palette')[flavor]
```

with:

```lua
  local palette = require('apple.palette').get(flavor, opts.contrast)
```

In `M.apply_new_integrations()`, replace:

```lua
  local palette = require('apple.palette')[resolve_flavor(opts)]
```

with:

```lua
  local palette = require('apple.palette').get(resolve_flavor(opts), opts.contrast)
```

- [ ] **Step 6: Format and run the tests**

```bash
stylua apple.nvim && stylua --check . && nvim --clean -l apple.nvim/tests/run.lua
```

Expected: the last line is `N passed, 0 failed`.

- [ ] **Step 7: Commit**

```bash
git add apple.nvim/lua/apple/config.lua apple.nvim/lua/apple/init.lua apple.nvim/tests/config_spec.lua apple.nvim/tests/colorscheme_spec.lua
git commit -m "Add the contrast option to the apple colorscheme

Written by Claude"
```

### Task A3: Docs and the config that uses the theme

**Files:**
- Modify: `apple.nvim/README.md:3-6`, `:43-59`, `:94-111`
- Modify: `init.lua:426-433`

**Interfaces:**
- Consumes: the `contrast` option from Task A2.
- Produces: nothing for other tasks.

- [ ] **Step 1: Update the README intro**

In `apple.nvim/README.md`, replace:

```markdown
A Neovim colorscheme built from Apple system colors
([Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/color)).
Two flavors, dark and light. The flavor follows `'background'`, so it switches
with your terminal and macOS appearance.
```

with:

```markdown
A Neovim colorscheme built from Apple system colors
([Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/color)).
Four flavors: dark and light, each with Apple's default colors or Apple's
increased contrast colors. Dark or light follows `'background'`, so it switches
with your terminal and macOS appearance.
```

- [ ] **Step 2: Update the README options**

Replace:

```lua
  flavor = 'auto',            -- 'auto' | 'dark' | 'light'
  styles = {
```

with:

```lua
  flavor = 'auto',            -- 'auto' | 'dark' | 'light'
  contrast = 'default',       -- 'default' | 'increased'
  styles = {
```

Replace:

```markdown
- `flavor = 'auto'` uses `'background'`. Never set `'background'` yourself in
  that mode, or Neovim stops following the terminal.
```

with:

```markdown
- `flavor = 'auto'` uses `'background'`. Never set `'background'` yourself in
  that mode, or Neovim stops following the terminal.
- `contrast = 'increased'` uses Apple's increased contrast colors for text,
  grays and the background. The colors are Apple's values as they are. In the
  default light flavor, yellow, orange, green and teal text is weak; use
  `contrast = 'increased'` if that bothers you.
```

- [ ] **Step 3: Update the README palette table**

Replace the whole table under `## Palette` (from `| name       | dark      | light     |` to the `| pink ...` row) with:

```markdown
| name    | dark      | light     | dark, increased | light, increased |
|---------|-----------|-----------|-----------------|------------------|
| bg      | `#1C1C1E` | `#F2F2F7` | `#242426`       | `#EBEBF0`        |
| bg_alt  | `#2C2C2E` | `#E5E5EA` | `#363638`       | `#D8D8DC`        |
| border  | `#48484A` | `#C7C7CC` | `#545456`       | `#AEAEB2`        |
| line_nr | `#636366` | `#AEAEB2` | `#7C7C80`       | `#8E8E93`        |
| comment | `#8E8E93` | `#8E8E93` | `#AEAEB2`       | `#6C6C70`        |
| fg      | `#F2F2F7` | `#1C1C1E` | `#F2F2F7`       | `#1C1C1E`        |
| red     | `#FF4245` | `#FF383C` | `#FF6165`       | `#E9152D`        |
| orange  | `#FF9230` | `#FF8D28` | `#FFA056`       | `#C55300`        |
| yellow  | `#FFD600` | `#FFCC00` | `#FEDF43`       | `#A16A00`        |
| green   | `#30D158` | `#34C759` | `#4AD968`       | `#008932`        |
| teal    | `#00D2E0` | `#00C3D0` | `#3BDDEC`       | `#008198`        |
| blue    | `#0091FF` | `#0088FF` | `#5CB8FF`       | `#1E6EF4`        |
| purple  | `#DB34F2` | `#CB30E0` | `#EA8DFF`       | `#B02FC2`        |
| pink    | `#FF375F` | `#FF2D55` | `#FF8AC4`       | `#E7124D`        |

In Lua the palettes are `require('apple.palette').dark`, `.light`,
`.dark_contrast` and `.light_contrast`.
```

- [ ] **Step 4: Check the README table against the code**

```bash
nvim --clean -l - <<'EOF'
vim.opt.runtimepath:prepend(vim.fn.getcwd() .. '/apple.nvim')
local palette = require 'apple.palette'
local readme = table.concat(vim.fn.readfile 'apple.nvim/README.md', '\n')
local bad = 0
for _, key in ipairs { 'bg', 'bg_alt', 'border', 'line_nr', 'comment', 'fg', 'red', 'orange', 'yellow', 'green', 'teal', 'blue', 'purple', 'pink' } do
  -- Lua pattern for one table row: the name, then the four colors in order.
  local row = '\n| ' .. key
  for _, flavor in ipairs { 'dark', 'light', 'dark_contrast', 'light_contrast' } do
    row = row .. '%s*| `' .. palette[flavor][key] .. '`'
  end
  if not readme:find(row) then
    bad = bad + 1
    print('README row is wrong: ' .. key)
  end
end
print(bad == 0 and 'README table matches the palette' or 'MISMATCH')
os.exit(bad == 0 and 0 or 1)
EOF
```

Expected: `README table matches the palette`.

- [ ] **Step 5: Show the option in the Neovim config**

In `init.lua` (repository root), replace:

```lua
    -- 'auto' follows 'background': dark terminal -> dark flavor, light -> light.
    flavor = 'auto',
    styles = {
```

with:

```lua
    -- 'auto' follows 'background': dark terminal -> dark flavor, light -> light.
    flavor = 'auto',
    -- 'default' uses Apple's default colors, 'increased' the increased contrast ones.
    contrast = 'default',
    styles = {
```

- [ ] **Step 6: Format, run the tests and start Neovim once**

```bash
stylua init.lua && stylua --check . && nvim --clean -l apple.nvim/tests/run.lua
nvim --headless '+lua print(vim.g.colors_name, require("apple.config").options.contrast)' +qa
```

Expected: `N passed, 0 failed`, then `apple default` (startup messages from plugins may come before it; there must be no Lua error).

- [ ] **Step 7: Commit**

```bash
git add apple.nvim/README.md init.lua
git commit -m "Document the four apple flavors and the contrast option

Written by Claude"
```

---

# Part B: Ghostty and Warp themes (repository `macos-configs`)

Work in `/Users/sergii/github/personal/macos-configs`.

Test command after Task B1 (from the repository root):

```bash
nvim --clean -l tests/themes/run.lua
```

### Task B1: Remove the minimal Neovim config and move the theme tests

**Files:**
- Delete: `nvim/` (whole stow package)
- Delete: `tests/nvim/colorscheme_spec.lua`, `tests/nvim/config_spec.lua`, `tests/nvim/palette_spec.lua`
- Move: `tests/nvim/run.lua`, `helpers.lua`, `hig.lua`, `themes_spec.lua` → `tests/themes/`
- Modify: `tests/themes/run.lua`, `tests/themes/helpers.lua`
- Modify: `README.md:189-232`

**Interfaces:**
- Consumes: nothing.
- Produces: `tests/themes/run.lua` (runner), and `tests/themes/helpers.lua` with `test(name, fn)`, `eq(expected, actual, msg)`, `ok(value, msg)`, `read_ghostty_theme(name)` → `{ palette = { [0..15] = '#RRGGBB' }, background = ..., foreground = ..., ['cursor-color'] = ..., ['cursor-text'] = ..., ['selection-background'] = ..., ['selection-foreground'] = ... }`, `read_warp_theme(name)` → `{ accent = ..., background = ..., foreground = ..., normal = { black = ..., ... }, bright = { ... } }`, `report()`.

- [ ] **Step 1: Create the branch and check that the old config is not in use**

```bash
cd /Users/sergii/github/personal/macos-configs
git switch -c apple-contrast-flavors
git status --short
readlink ~/.config/nvim
```

Expected: the status still lists the user's uncommitted files (leave them alone). `readlink` prints `/Users/sergii/github/personal/neovim-config`. If it prints a path inside `macos-configs`, stop and ask the user.

- [ ] **Step 2: Check the tests pass before the change**

Run: `nvim --clean -l tests/nvim/run.lua`

Expected: `N passed, 0 failed`.

- [ ] **Step 3: Delete the config and its tests, move the theme tests**

```bash
git rm -r -q nvim
git rm -q tests/nvim/colorscheme_spec.lua tests/nvim/config_spec.lua tests/nvim/palette_spec.lua
mkdir -p tests/themes
git mv tests/nvim/run.lua tests/nvim/helpers.lua tests/nvim/hig.lua tests/nvim/themes_spec.lua tests/themes/
ls tests
```

Expected: `ls tests` prints only `themes`.

- [ ] **Step 4: Update the runner**

Replace the whole content of `tests/themes/run.lua` with:

```lua
-- Test runner for the Apple themes (Ghostty and Warp).
-- Run from the repository root: nvim --clean -l tests/themes/run.lua
local root = vim.fn.getcwd()
package.path = root .. '/tests/themes/?.lua;' .. package.path

local t = require('helpers')
for _, file in ipairs(vim.fn.glob(root .. '/tests/themes/*_spec.lua', false, true)) do
  print('\n# ' .. vim.fn.fnamemodify(file, ':t'))
  dofile(file)
end
os.exit(t.report())
```

- [ ] **Step 5: Remove helpers that nothing uses now**

In `tests/themes/helpers.lua`, delete these blocks:

```lua
-- WCAG relative luminance of one color channel (0-255).
local function channel(c)
  c = c / 255
  return c <= 0.03928 and c / 12.92 or ((c + 0.055) / 1.055) ^ 2.4
end

local function luminance(hex)
  local r = tonumber(hex:sub(2, 3), 16)
  local g = tonumber(hex:sub(4, 5), 16)
  local b = tonumber(hex:sub(6, 7), 16)
  return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)
end

-- WCAG contrast ratio between two '#RRGGBB' colors (1 to 21).
function M.contrast(a, b)
  local x, y = luminance(a), luminance(b)
  if x < y then
    x, y = y, x
  end
  return (x + 0.05) / (y + 0.05)
end

function M.min_contrast(fg, bg, min, label)
  local ratio = M.contrast(fg, bg)
  if ratio < min then
    error(('%s: %s on %s has %.2f:1, needs %.1f:1'):format(label, fg, bg, ratio, min), 2)
  end
end

-- Convert a color number from nvim_get_hl() to '#RRGGBB'.
function M.hex(n)
  return n and ('#%06X'):format(n) or nil
end

```

and:

```lua
-- Forget loaded Lua modules, so the next require() reads the files again.
function M.unload(prefix)
  for name in pairs(package.loaded) do
    if name == prefix or vim.startswith(name, prefix .. '.') then
      package.loaded[name] = nil
    end
  end
end

```

The file keeps `test`, `eq`, `ok`, `read_ghostty_theme`, `read_warp_theme` and `report`.

- [ ] **Step 6: Replace the Neovim section in the README**

In `README.md`, replace everything from the line `## NEOVIM CONFIGURATION` up to (not including) the line `## GIT CONFIGURATION` with:

````markdown
## APPLE THEMES

The Ghostty and Warp themes use Apple system colors from the [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/color). To check the values, run the tests from the repository root (they need [NeoVim](https://neovim.io) as the Lua runner):

```shell
nvim --clean -l tests/themes/run.lua
```

> [!NOTE]
> The NeoVim configuration lives in its own repository: [neovim-config](https://github.com/sergiivelykodnyi/neovim-config). It has the `apple` colorscheme with the same colors.

````

- [ ] **Step 7: Run the tests and look for leftovers**

```bash
nvim --clean -l tests/themes/run.lua
grep -rn 'tests/nvim\|kvim\|stow --verbose.*nvim\|nvim/.config' README.md tests .stowrc
```

Expected: `N passed, 0 failed` (only `themes_spec.lua` runs). `grep` prints nothing.

- [ ] **Step 8: Commit**

```bash
git add README.md tests/themes
git status --short
git commit -m "Remove the minimal Neovim config and keep the theme tests

The Neovim config now lives in the neovim-config repository.

Written by Claude"
```

Before the commit, `git status --short` must show the deletions under `nvim/` and `tests/nvim/`, the renames to `tests/themes/` and `README.md` as staged (first column), and the user's files only as unstaged (second column). After the commit, `git show --stat HEAD` must not list `ghostty/.config/ghostty/config`, `git/`, `herdr/`, `oh-my-posh/`, `zsh/` or `lazygit/`.

### Task B2: Four flavors for Ghostty and Warp

**Files:**
- Modify (rewrite): `tests/themes/themes_spec.lua`
- Modify: `ghostty/.config/ghostty/themes/apple-dark`, `ghostty/.config/ghostty/themes/apple-light`
- Create: `ghostty/.config/ghostty/themes/apple-dark-contrast`, `ghostty/.config/ghostty/themes/apple-light-contrast`
- Modify: `warp/.warp/themes/apple_dark.yaml`, `warp/.warp/themes/apple_light.yaml`
- Create: `warp/.warp/themes/apple_dark_contrast.yaml`, `warp/.warp/themes/apple_light_contrast.yaml`
- Modify: `README.md` (the `## APPLE THEMES` section from Task B1)

**Interfaces:**
- Consumes: `tests/themes/helpers.lua` and `tests/themes/hig.lua` from Task B1.
- Produces: nothing for other tasks.

- [ ] **Step 1: Write the failing test**

Replace the whole content of `tests/themes/themes_spec.lua` with:

```lua
local t = require('helpers')
local hig = require('hig')

-- ANSI slot of each Apple color. Normal color = slot, bright color = slot + 8.
local slots = { red = 1, green = 2, yellow = 3, blue = 4, purple = 5, cyan = 6 }

-- Warp names for ANSI slots 0-7.
local warp_names = { 'black', 'red', 'green', 'yellow', 'blue', 'magenta', 'cyan', 'white' }

-- ANSI slots 0, 7, 8 and 15 (black and white). The same in both contrasts.
local black_white = {
  dark = { [0] = '#F2F2F7', [7] = '#2C2C2E', [8] = '#EBEBF0', [15] = '#252526' },
  light = { [0] = '#252526', [7] = '#E5E5EA', [8] = '#2C2C2E', [15] = '#EBEBF0' },
}

-- column: the hig.lua column for colors that follow the contrast.
local flavors = {
  { ghostty = 'apple-dark', warp = 'apple_dark.yaml', mode = 'dark', column = 'dark' },
  { ghostty = 'apple-light', warp = 'apple_light.yaml', mode = 'light', column = 'light' },
  { ghostty = 'apple-dark-contrast', warp = 'apple_dark_contrast.yaml', mode = 'dark', column = 'hc_dark' },
  { ghostty = 'apple-light-contrast', warp = 'apple_light_contrast.yaml', mode = 'light', column = 'hc_light' },
}

local function is_hex(s)
  return type(s) == 'string' and s:match('^#%x%x%x%x%x%x$') ~= nil
end

for _, f in ipairs(flavors) do
  local mode, column = f.mode, f.column
  local hc = 'hc_' .. mode
  local other = mode == 'dark' and 'light' or 'dark'

  -- The files are read inside the tests, so a missing file fails one test
  -- and does not stop the runner.
  local function ghostty()
    return t.read_ghostty_theme(f.ghostty)
  end
  local function warp()
    return t.read_warp_theme(f.warp)
  end

  -- Review focus 5: an incomplete file must be reported by file and key.
  t.test(f.ghostty .. ': has all 16 colors and all base keys', function()
    local theme = ghostty()
    for i = 0, 15 do
      t.ok(is_hex(theme.palette[i]), f.ghostty .. ': palette ' .. i .. ' is missing or not #RRGGBB')
    end
    for _, key in ipairs({ 'background', 'foreground', 'cursor-color', 'cursor-text', 'selection-background', 'selection-foreground' }) do
      t.ok(is_hex(theme[key]), f.ghostty .. ': ' .. key .. ' is missing or not #RRGGBB')
    end
  end)

  t.test(f.ghostty .. ': normal colors follow the flavor, bright colors are increased contrast', function()
    local theme = ghostty()
    for name, slot in pairs(slots) do
      t.eq(hig[name][column], theme.palette[slot], name .. ' (slot ' .. slot .. ')')
      t.eq(hig[name][hc], theme.palette[slot + 8], name .. ' (slot ' .. (slot + 8) .. ')')
    end
  end)

  t.test(f.ghostty .. ': black and white slots keep their values', function()
    local theme = ghostty()
    for slot, color in pairs(black_white[mode]) do
      t.eq(color, theme.palette[slot], 'slot ' .. slot)
    end
  end)

  t.test(f.ghostty .. ': background and cursor are the HIG colors of the flavor', function()
    local theme = ghostty()
    t.eq(hig.gray6[column], theme['background'], 'background')
    t.eq(hig.indigo[column], theme['cursor-color'], 'cursor-color')
  end)

  t.test(f.ghostty .. ': foreground, cursor text and selection do not follow the contrast', function()
    local theme = ghostty()
    t.eq(hig.gray6[other], theme['foreground'], 'foreground')
    t.eq('#1C1C1E', theme['cursor-text'], 'cursor-text')
    t.eq('#A7AAFF', theme['selection-background'], 'selection-background')
    t.eq('#1C1C1E', theme['selection-foreground'], 'selection-foreground')
  end)

  t.test(f.warp .. ': has the same colors as ' .. f.ghostty, function()
    local g, w = ghostty(), warp()
    t.eq(g.background, w.background, 'background')
    t.eq(g.foreground, w.foreground, 'foreground')
    for i, name in ipairs(warp_names) do
      t.ok(is_hex(w.normal[name]), f.warp .. ': normal ' .. name .. ' is missing or not #RRGGBB')
      t.ok(is_hex(w.bright[name]), f.warp .. ': bright ' .. name .. ' is missing or not #RRGGBB')
      t.eq(g.palette[i - 1], w.normal[name], 'normal ' .. name)
      t.eq(g.palette[i + 7], w.bright[name], 'bright ' .. name)
    end
  end)

  t.test(f.warp .. ': has the accent color and the right details value', function()
    t.eq('#A7AAFF', warp().accent, f.warp .. ': accent')
    local path = vim.fn.getcwd() .. '/warp/.warp/themes/' .. f.warp
    local details
    for _, line in ipairs(vim.fn.readfile(path)) do
      details = details or line:match('^details:%s*(%a+)')
    end
    t.eq(mode == 'dark' and 'darker' or 'lighter', details, f.warp .. ': details')
  end)
end
```

- [ ] **Step 2: Run the tests to see them fail**

Run: `nvim --clean -l tests/themes/run.lua`

Expected: failures such as `FAIL apple-dark: normal colors follow the flavor, bright colors are increased contrast` (`red (slot 1): expected "#FF4245", got "#FF6165"`), and for the contrast flavors `No such file or directory` errors. The last line shows more than 0 failed.

- [ ] **Step 3: Write the Ghostty default dark theme**

Replace the whole content of `ghostty/.config/ghostty/themes/apple-dark` with:

```
palette = 0=#F2F2F7
palette = 1=#FF4245
palette = 2=#30D158
palette = 3=#FFD600
palette = 4=#0091FF
palette = 5=#DB34F2
palette = 6=#3CD3FE
palette = 7=#2C2C2E
palette = 8=#EBEBF0
palette = 9=#FF6165
palette = 10=#4AD968
palette = 11=#FEDF43
palette = 12=#5CB8FF
palette = 13=#EA8DFF
palette = 14=#6DD9FF
palette = 15=#252526
background = #1C1C1E
foreground = #F2F2F7
cursor-color = #6D7CFF
cursor-text = #1C1C1E
selection-background = #A7AAFF
selection-foreground = #1C1C1E
```

- [ ] **Step 4: Write the Ghostty default light theme**

Replace the whole content of `ghostty/.config/ghostty/themes/apple-light` with:

```
palette = 0=#252526
palette = 1=#FF383C
palette = 2=#34C759
palette = 3=#FFCC00
palette = 4=#0088FF
palette = 5=#CB30E0
palette = 6=#00C0E8
palette = 7=#E5E5EA
palette = 8=#2C2C2E
palette = 9=#E9152D
palette = 10=#008932
palette = 11=#A16A00
palette = 12=#1E6EF4
palette = 13=#B02FC2
palette = 14=#007EAE
palette = 15=#EBEBF0
background = #F2F2F7
foreground = #1C1C1E
cursor-color = #6155F5
cursor-text = #1C1C1E
selection-background = #A7AAFF
selection-foreground = #1C1C1E
```

- [ ] **Step 5: Write the Ghostty increased contrast dark theme**

Create `ghostty/.config/ghostty/themes/apple-dark-contrast` with:

```
palette = 0=#F2F2F7
palette = 1=#FF6165
palette = 2=#4AD968
palette = 3=#FEDF43
palette = 4=#5CB8FF
palette = 5=#EA8DFF
palette = 6=#6DD9FF
palette = 7=#2C2C2E
palette = 8=#EBEBF0
palette = 9=#FF6165
palette = 10=#4AD968
palette = 11=#FEDF43
palette = 12=#5CB8FF
palette = 13=#EA8DFF
palette = 14=#6DD9FF
palette = 15=#252526
background = #242426
foreground = #F2F2F7
cursor-color = #A7AAFF
cursor-text = #1C1C1E
selection-background = #A7AAFF
selection-foreground = #1C1C1E
```

- [ ] **Step 6: Write the Ghostty increased contrast light theme**

Create `ghostty/.config/ghostty/themes/apple-light-contrast` with:

```
palette = 0=#252526
palette = 1=#E9152D
palette = 2=#008932
palette = 3=#A16A00
palette = 4=#1E6EF4
palette = 5=#B02FC2
palette = 6=#007EAE
palette = 7=#E5E5EA
palette = 8=#2C2C2E
palette = 9=#E9152D
palette = 10=#008932
palette = 11=#A16A00
palette = 12=#1E6EF4
palette = 13=#B02FC2
palette = 14=#007EAE
palette = 15=#EBEBF0
background = #EBEBF0
foreground = #1C1C1E
cursor-color = #564ADE
cursor-text = #1C1C1E
selection-background = #A7AAFF
selection-foreground = #1C1C1E
```

- [ ] **Step 7: Write the Warp default dark theme**

Replace the whole content of `warp/.warp/themes/apple_dark.yaml` with:

```yaml
accent: "#A7AAFF" # Accent color for UI elements
background: "#1C1C1E" # Terminal background color
foreground: "#F2F2F7" # The foreground color
details: darker # Whether the theme is lighter or darker
terminal_colors: # Ansi escape colors
  bright:
    black: "#EBEBF0"
    blue: "#5CB8FF"
    cyan: "#6DD9FF"
    green: "#4AD968"
    magenta: "#EA8DFF"
    red: "#FF6165"
    white: "#252526"
    yellow: "#FEDF43"
  normal:
    black: "#F2F2F7"
    blue: "#0091FF"
    cyan: "#3CD3FE"
    green: "#30D158"
    magenta: "#DB34F2"
    red: "#FF4245"
    white: "#2C2C2E"
    yellow: "#FFD600"
```

- [ ] **Step 8: Write the Warp default light theme**

Replace the whole content of `warp/.warp/themes/apple_light.yaml` with:

```yaml
accent: "#A7AAFF" # Accent color for UI elements
background: "#F2F2F7" # Terminal background color
foreground: "#1C1C1E" # The foreground color
details: lighter # Whether the theme is lighter or darker
terminal_colors: # Ansi escape colors
  bright:
    black: "#2C2C2E"
    blue: "#1E6EF4"
    cyan: "#007EAE"
    green: "#008932"
    magenta: "#B02FC2"
    red: "#E9152D"
    white: "#EBEBF0"
    yellow: "#A16A00"
  normal:
    black: "#252526"
    blue: "#0088FF"
    cyan: "#00C0E8"
    green: "#34C759"
    magenta: "#CB30E0"
    red: "#FF383C"
    white: "#E5E5EA"
    yellow: "#FFCC00"
```

- [ ] **Step 9: Write the Warp increased contrast dark theme**

Create `warp/.warp/themes/apple_dark_contrast.yaml` with:

```yaml
accent: "#A7AAFF" # Accent color for UI elements
background: "#242426" # Terminal background color
foreground: "#F2F2F7" # The foreground color
details: darker # Whether the theme is lighter or darker
terminal_colors: # Ansi escape colors
  bright:
    black: "#EBEBF0"
    blue: "#5CB8FF"
    cyan: "#6DD9FF"
    green: "#4AD968"
    magenta: "#EA8DFF"
    red: "#FF6165"
    white: "#252526"
    yellow: "#FEDF43"
  normal:
    black: "#F2F2F7"
    blue: "#5CB8FF"
    cyan: "#6DD9FF"
    green: "#4AD968"
    magenta: "#EA8DFF"
    red: "#FF6165"
    white: "#2C2C2E"
    yellow: "#FEDF43"
```

- [ ] **Step 10: Write the Warp increased contrast light theme**

Create `warp/.warp/themes/apple_light_contrast.yaml` with:

```yaml
accent: "#A7AAFF" # Accent color for UI elements
background: "#EBEBF0" # Terminal background color
foreground: "#1C1C1E" # The foreground color
details: lighter # Whether the theme is lighter or darker
terminal_colors: # Ansi escape colors
  bright:
    black: "#2C2C2E"
    blue: "#1E6EF4"
    cyan: "#007EAE"
    green: "#008932"
    magenta: "#B02FC2"
    red: "#E9152D"
    white: "#EBEBF0"
    yellow: "#A16A00"
  normal:
    black: "#252526"
    blue: "#1E6EF4"
    cyan: "#007EAE"
    green: "#008932"
    magenta: "#B02FC2"
    red: "#E9152D"
    white: "#E5E5EA"
    yellow: "#A16A00"
```

- [ ] **Step 11: Run the tests**

Run: `nvim --clean -l tests/themes/run.lua`

Expected: `28 passed, 0 failed` (7 tests for each of the 4 flavors).

- [ ] **Step 12: Describe the flavors in the README**

In `README.md`, in the `## APPLE THEMES` section, add this after the first paragraph's code block (after the closing ` ``` ` of the test command) and before the `> [!NOTE]` block:

````markdown
There are four flavors. The default flavors use Apple's default colors, the contrast flavors use Apple's increased contrast colors:

| Flavor | Ghostty theme | Warp theme |
|---|---|---|
| Default dark | `apple-dark` | `apple_dark.yaml` |
| Default light | `apple-light` | `apple_light.yaml` |
| Increased contrast dark | `apple-dark-contrast` | `apple_dark_contrast.yaml` |
| Increased contrast light | `apple-light-contrast` | `apple_light_contrast.yaml` |

To use the increased contrast flavors in Ghostty, change the `theme` line in `ghostty/.config/ghostty/config`:

```
theme = light:apple-light-contrast,dark:apple-dark-contrast
```

````

- [ ] **Step 13: Check that Ghostty accepts the themes**

```bash
ls -l ~/.config/ghostty/themes
ghostty +list-themes --plain 2>/dev/null | grep -i '^apple' || echo 'could not list themes with the ghostty CLI: skip this check'
```

Expected: `~/.config/ghostty/themes` is a symlink into this repository (so the new files are already visible to Ghostty), and the list shows `apple-dark`, `apple-dark-contrast`, `apple-light`, `apple-light-contrast`. If the CLI cannot list the themes (it is often not on PATH on macOS), skip the second command and say so in the report.

- [ ] **Step 14: Commit**

```bash
git add tests/themes/themes_spec.lua README.md \
  ghostty/.config/ghostty/themes/apple-dark ghostty/.config/ghostty/themes/apple-light \
  ghostty/.config/ghostty/themes/apple-dark-contrast ghostty/.config/ghostty/themes/apple-light-contrast \
  warp/.warp/themes/apple_dark.yaml warp/.warp/themes/apple_light.yaml \
  warp/.warp/themes/apple_dark_contrast.yaml warp/.warp/themes/apple_light_contrast.yaml
git commit -m "Add default and increased contrast flavors to the Ghostty and Warp Apple themes

Written by Claude"
git show --stat HEAD
```

Expected: the commit lists only the ten files above. `ghostty/.config/ghostty/config` is not in it.

---

## After both parts

- Ask the user to look at the result: open a new Ghostty window (dark and light), and open Neovim. Colors that look poor are noted for a later fix; they are not a failure of this plan.
- Use superpowers:finishing-a-development-branch for each repository. Pushing and opening the two pull requests needs the user's OK.
