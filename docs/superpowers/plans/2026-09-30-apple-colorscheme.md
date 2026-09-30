# apple.nvim Colorscheme Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the `apple` Neovim colorscheme as a self-contained plugin folder `apple.nvim/` inside this config, with dark/light flavors that follow the terminal, auto-detected plugin integrations, tests and CI, and switch `init.lua` from Catppuccin to it.

**Architecture:** Tokyonight-style modules under `apple.nvim/lua/apple/`: `palette.lua` (colors), `config.lua` (options), `util.lua` (helpers), `groups/*.lua` (pure functions returning highlight tables, one file per area or plugin), `groups/init.lua` (merge core + detected integrations), `init.lua` (`setup()` and `load()`), and `colors/apple.lua` (entry point). Tests are plain Lua run with `nvim --clean -l`.

**Tech Stack:** Neovim 0.11+ Lua API (`nvim_set_hl`, `nvim_get_runtime_file`), no external Lua libraries, stylua for formatting, GitHub Actions for CI.

**Spec:** `docs/superpowers/specs/2026-09-30-apple-colorscheme-design.md`

## Global Constraints

- Neovim 0.11+ (user runs 0.12.5). No busted, no plenary in tests.
- Palette values are exactly the ones in the spec's source (`macos-configs`), copied verbatim in Task 2. Never change a hex value.
- Group files (`lua/apple/groups/*.lua`) never call `vim.api`. Only `util.apply` and `init.load` touch the API.
- Colorscheme name is `apple`. Module name is `apple`. Plugin folder is `apple.nvim/` at the repo root.
- Style tables from `setup()` **replace** the default for that key (so `keywords = {}` removes bold).
- Code comments in simple English. Format with stylua (`.stylua.toml`: 2 spaces, single quotes, no call parentheses, width 160). If `stylua` is missing, install it with `brew install stylua` before Task 1.
- Commit messages end with exactly one trailer line: `Written by Claude`. No email, no session link.
- Every test file lives in `apple.nvim/tests/` and is named `*_spec.lua`. Run all tests with `nvim --clean -l apple.nvim/tests/run.lua` from the repo root.

## Review Focus

Inputs the spec implies but does not spell out. Each has a test in the task named.

1. `:colorscheme apple` with no `setup()` call must work with defaults (Task 4, colorscheme_spec).
2. `setup { styles = { keywords = {} } }` must remove bold; deep-merge would keep it (Task 3, config_spec).
3. In `auto` mode, changing `background` after load must switch the flavor and keep `colors_name = 'apple'` (Task 6, colorscheme_spec).
4. If `on_highlights` throws, the next `:colorscheme apple` must still work (the reload guard must reset) (Task 6, colorscheme_spec).
5. `integrations = { unknown_name = true }` must be ignored, not crash (Task 7, integrations_spec).

---

### Task 1: Plugin skeleton, test runner and `util`

**Files:**
- Create: `apple.nvim/tests/run.lua`
- Create: `apple.nvim/tests/helpers.lua`
- Create: `apple.nvim/tests/util_spec.lua`
- Create: `apple.nvim/lua/apple/util.lua`

**Interfaces:**
- Produces: `require('apple.util')` with
  - `mix(fg: string, bg: string, amount: number): string` — blends `#RRGGBB` colors, `amount = 1` gives `fg`.
  - `has_plugin(names: string | string[]): boolean` — plugin available on the runtimepath or already loaded.
  - `apply(groups: table<string, vim.api.keyset.highlight>)` — calls `nvim_set_hl(0, ...)` for each entry.
- Produces: test helper `require('helpers')` with `test(name, fn)`, `eq(expected, actual, msg)`, `ok(value, msg)`, `hex(n)`, `contrast(a, b)`, `min_contrast(fg, bg, min, label)`, `unload(prefix)`, `report()`.

- [ ] **Step 1: Create the test runner**

`apple.nvim/tests/run.lua`:

```lua
-- Test runner for apple.nvim.
-- Run from anywhere: nvim --clean -l apple.nvim/tests/run.lua
local script = debug.getinfo(1, 'S').source:sub(2)
local root = vim.fn.fnamemodify(script, ':p:h:h')

vim.opt.runtimepath:prepend(root)
package.path = root .. '/tests/?.lua;' .. package.path

local t = require 'helpers'
local specs = vim.fn.glob(root .. '/tests/*_spec.lua', false, true)
table.sort(specs)
for _, file in ipairs(specs) do
  print('\n# ' .. vim.fn.fnamemodify(file, ':t'))
  dofile(file)
end
os.exit(t.report())
```

- [ ] **Step 2: Create the test helper**

`apple.nvim/tests/helpers.lua`:

```lua
-- Small helpers for headless tests. No external test library is needed.
local M = { passed = 0, failed = 0 }

-- Run one test. An error inside fn marks the test as failed.
function M.test(name, fn)
  local ok, err = pcall(fn)
  if ok then
    M.passed = M.passed + 1
    print('ok   ' .. name)
  else
    M.failed = M.failed + 1
    print('FAIL ' .. name .. '\n     ' .. tostring(err))
  end
end

function M.eq(expected, actual, msg)
  if not vim.deep_equal(expected, actual) then
    error(('%s: expected %s, got %s'):format(msg or 'eq', vim.inspect(expected), vim.inspect(actual)), 2)
  end
end

function M.ok(value, msg)
  if not value then error(msg or 'expected a true value', 2) end
end

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
  if x < y then x, y = y, x end
  return (x + 0.05) / (y + 0.05)
end

function M.min_contrast(fg, bg, min, label)
  local ratio = M.contrast(fg, bg)
  if ratio < min then error(('%s: %s on %s has %.2f:1, needs %.1f:1'):format(label, fg, bg, ratio, min), 2) end
end

-- Convert a color number from nvim_get_hl() to '#RRGGBB'.
function M.hex(n)
  return n and ('#%06X'):format(n) or nil
end

-- Forget loaded Lua modules, so the next require() reads the files again.
function M.unload(prefix)
  for name in pairs(package.loaded) do
    if name == prefix or vim.startswith(name, prefix .. '.') then package.loaded[name] = nil end
  end
end

-- Print a summary and return the exit code.
function M.report()
  print(('\n%d passed, %d failed'):format(M.passed, M.failed))
  return M.failed == 0 and 0 or 1
end

return M
```

- [ ] **Step 3: Write the failing util tests**

`apple.nvim/tests/util_spec.lua`:

```lua
local t = require 'helpers'
local util = require 'apple.util'

t.test('mix blends two colors', function()
  t.eq('#808080', util.mix('#FFFFFF', '#000000', 0.5))
  t.eq('#0000FF', util.mix('#FF0000', '#0000FF', 0))
  t.eq('#FF0000', util.mix('#FF0000', '#0000FF', 1))
end)

t.test('has_plugin is true for a loaded module', function()
  t.eq(true, util.has_plugin 'apple.util')
end)

t.test('has_plugin finds a module file on the runtimepath', function()
  -- Forget the module, so only the file lua/apple/util.lua can be found.
  package.loaded['apple.util'] = nil
  t.eq(true, util.has_plugin 'apple.util')
  package.loaded['apple.util'] = util
end)

t.test('has_plugin finds a folder of modules on the runtimepath', function()
  -- lua/apple/ has no init.lua yet, but it has util.lua (lua/apple/*.lua).
  t.eq(true, util.has_plugin 'apple')
end)

t.test('has_plugin is false for an unknown plugin', function()
  t.eq(false, util.has_plugin 'this-plugin-does-not-exist')
end)

t.test('has_plugin accepts a list and returns true when any matches', function()
  t.eq(true, util.has_plugin { 'nope', 'apple.util' })
  t.eq(false, util.has_plugin { 'nope', 'nope2' })
end)

t.test('apply sets highlight groups', function()
  util.apply { AppleTestGroup = { fg = '#FF0000', bold = true } }
  local def = vim.api.nvim_get_hl(0, { name = 'AppleTestGroup' })
  t.eq('#FF0000', t.hex(def.fg))
  t.eq(true, def.bold)
end)
```

- [ ] **Step 4: Run the tests to see them fail**

Run: `nvim --clean -l apple.nvim/tests/run.lua`
Expected: an error like `module 'apple.util' not found`, exit code non-zero.

- [ ] **Step 5: Implement util**

`apple.nvim/lua/apple/util.lua`:

```lua
-- Small helpers shared by the apple colorscheme.
local M = {}

-- Mix two '#RRGGBB' colors. amount = 0 gives bg, amount = 1 gives fg.
function M.mix(fg, bg, amount)
  local channels = {}
  for i = 2, 6, 2 do
    local a = tonumber(fg:sub(i, i + 1), 16)
    local b = tonumber(bg:sub(i, i + 1), 16)
    channels[#channels + 1] = math.floor(a * amount + b * (1 - amount) + 0.5)
  end
  return ('#%02X%02X%02X'):format(channels[1], channels[2], channels[3])
end

-- True when a plugin is available.
-- `names` is a Lua module name ('telescope', 'blink.cmp') or a list of them.
-- A plugin counts as available when its module is already loaded, or when
-- lua/<name>.lua, lua/<name>/init.lua or lua/<name>/*.lua is on the runtimepath.
function M.has_plugin(names)
  if type(names) == 'string' then names = { names } end
  for _, name in ipairs(names) do
    if package.loaded[name] then return true end
    local path = 'lua/' .. name:gsub('%.', '/')
    for _, pattern in ipairs { path .. '.lua', path .. '/init.lua', path .. '/*.lua' } do
      if #vim.api.nvim_get_runtime_file(pattern, false) > 0 then return true end
    end
  end
  return false
end

-- Set every highlight group in the table.
function M.apply(groups)
  for name, def in pairs(groups) do
    vim.api.nvim_set_hl(0, name, def)
  end
end

return M
```

- [ ] **Step 6: Run the tests to see them pass**

Run: `nvim --clean -l apple.nvim/tests/run.lua`
Expected: `7 passed, 0 failed`, exit code 0.

- [ ] **Step 7: Format and commit**

```bash
stylua apple.nvim
git add apple.nvim
git commit -m "Add apple.nvim skeleton, test runner and util module

Written by Claude"
```

---

### Task 2: Palette

**Files:**
- Create: `apple.nvim/lua/apple/palette.lua`
- Create: `apple.nvim/tests/hig.lua`
- Create: `apple.nvim/tests/palette_spec.lua`

**Interfaces:**
- Consumes: `util.mix`.
- Produces: `require('apple.palette')` with `M.dark` and `M.light`. Keys: `bg, bg_alt, border, line_nr, comment, fg, cursor, selection, selection_fg, search, cur_search, search_fg, red, orange, yellow, green, teal, blue, purple, pink, diff_add, diff_change, diff_delete, diff_add_bg, diff_change_bg, diff_delete_bg, diff_text_bg, none, terminal` (list of 16).

- [ ] **Step 1: Create the HIG reference table for tests**

`apple.nvim/tests/hig.lua`:

```lua
-- Apple HIG system colors, from
-- https://developer.apple.com/design/human-interface-guidelines/color (June 2025 values).
-- light / dark: default values. hc_light / hc_dark: increased contrast values.
return {
  red = { light = '#FF383C', dark = '#FF4245', hc_light = '#E9152D', hc_dark = '#FF6165' },
  orange = { light = '#FF8D28', dark = '#FF9230', hc_light = '#C55300', hc_dark = '#FFA056' },
  yellow = { light = '#FFCC00', dark = '#FFD600', hc_light = '#A16A00', hc_dark = '#FEDF43' },
  green = { light = '#34C759', dark = '#30D158', hc_light = '#008932', hc_dark = '#4AD968' },
  mint = { light = '#00C8B3', dark = '#00DAC3', hc_light = '#008575', hc_dark = '#54DFCB' },
  teal = { light = '#00C3D0', dark = '#00D2E0', hc_light = '#008198', hc_dark = '#3BDDEC' },
  cyan = { light = '#00C0E8', dark = '#3CD3FE', hc_light = '#007EAE', hc_dark = '#6DD9FF' },
  blue = { light = '#0088FF', dark = '#0091FF', hc_light = '#1E6EF4', hc_dark = '#5CB8FF' },
  indigo = { light = '#6155F5', dark = '#6D7CFF', hc_light = '#564ADE', hc_dark = '#A7AAFF' },
  purple = { light = '#CB30E0', dark = '#DB34F2', hc_light = '#B02FC2', hc_dark = '#EA8DFF' },
  pink = { light = '#FF2D55', dark = '#FF375F', hc_light = '#E7124D', hc_dark = '#FF8AC4' },
  brown = { light = '#AC7F5E', dark = '#B78A66', hc_light = '#956D51', hc_dark = '#DBA679' },
  gray = { light = '#8E8E93', dark = '#8E8E93', hc_light = '#6C6C70', hc_dark = '#AEAEB2' },
  gray2 = { light = '#AEAEB2', dark = '#636366', hc_light = '#8E8E93', hc_dark = '#7C7C80' },
  gray3 = { light = '#C7C7CC', dark = '#48484A', hc_light = '#AEAEB2', hc_dark = '#545456' },
  gray4 = { light = '#D1D1D6', dark = '#3A3A3C', hc_light = '#BCBCC0', hc_dark = '#444446' },
  gray5 = { light = '#E5E5EA', dark = '#2C2C2E', hc_light = '#D8D8DC', hc_dark = '#363638' },
  gray6 = { light = '#F2F2F7', dark = '#1C1C1E', hc_light = '#EBEBF0', hc_dark = '#242426' },
}
```

- [ ] **Step 2: Write the failing palette tests**

`apple.nvim/tests/palette_spec.lua`:

```lua
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
```

- [ ] **Step 3: Run the tests to see them fail**

Run: `nvim --clean -l apple.nvim/tests/run.lua`
Expected: error `module 'apple.palette' not found`.

- [ ] **Step 4: Create the palette**

`apple.nvim/lua/apple/palette.lua`:

```lua
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
  teal = '#3BDDEC',
  blue = '#5CB8FF',
  purple = '#EA8DFF',
  pink = '#FF8AC4',

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
    '#F2F2F7', '#FF6165', '#4AD968', '#FEDF43', '#5CB8FF', '#EA8DFF', '#6DD9FF', '#2C2C2E',
    '#EBEBF0', '#FF4245', '#30D158', '#FFD600', '#0091FF', '#DB34F2', '#3CD3FE', '#252526',
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
  teal = '#008198',
  blue = '#1E6EF4',
  purple = '#B02FC2',
  pink = '#E7124D',

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
    '#252526', '#E9152D', '#008932', '#A16A00', '#1E6EF4', '#B02FC2', '#007EAE', '#E5E5EA',
    '#2C2C2E', '#FF383C', '#34C759', '#FFCC00', '#0088FF', '#CB30E0', '#00C0E8', '#EBEBF0',
  },
}

return M
```

Note: stylua may reflow the `terminal` lists onto one item per line. That is fine.

- [ ] **Step 5: Run the tests to see them pass**

Run: `nvim --clean -l apple.nvim/tests/run.lua`
Expected: all tests pass (`19 passed, 0 failed`: 7 from util + 12 from palette), exit 0.

- [ ] **Step 6: Format and commit**

```bash
stylua apple.nvim
git add apple.nvim
git commit -m "Add apple palette with HIG colors and tests

Written by Claude"
```

---

### Task 3: Config

**Files:**
- Create: `apple.nvim/lua/apple/config.lua`
- Create: `apple.nvim/tests/config_spec.lua`

**Interfaces:**
- Produces: `require('apple.config')` with
  - `M.defaults` (table, see below)
  - `M.options` (current options, starts as a copy of defaults)
  - `M.extend(opts?: table): table` — resets from defaults, merges `opts`, returns and stores the result. Keys under `styles` replace, everything else deep-merges.

- [ ] **Step 1: Write the failing config tests**

`apple.nvim/tests/config_spec.lua`:

```lua
local t = require 'helpers'
local config = require 'apple.config'

t.test('defaults: auto flavor, plain comments, bold keywords', function()
  t.eq('auto', config.defaults.flavor)
  t.eq({}, config.defaults.styles.comments)
  t.eq({ bold = true }, config.defaults.styles.keywords)
  t.eq({}, config.defaults.styles.functions)
  t.eq({}, config.defaults.styles.strings)
  t.eq({}, config.defaults.integrations)
  t.eq(nil, config.defaults.on_highlights)
end)

t.test('options start equal to defaults', function()
  t.eq(config.defaults, config.options)
end)

t.test('extend merges user options over defaults', function()
  local o = config.extend { flavor = 'light', integrations = { telescope = false } }
  t.eq('light', o.flavor)
  t.eq(false, o.integrations.telescope)
  t.eq({ bold = true }, o.styles.keywords, 'untouched style keeps default')
  t.eq(o, config.options, 'result is stored')
end)

t.test('extend resets to defaults each call', function()
  config.extend { flavor = 'light' }
  local o = config.extend {}
  t.eq('auto', o.flavor)
end)

-- Review focus 2: a style table replaces the default, so {} removes bold.
t.test('a style table replaces the default instead of merging', function()
  local o = config.extend { styles = { keywords = {}, comments = { italic = true } } }
  t.eq({}, o.styles.keywords)
  t.eq({ italic = true }, o.styles.comments)
  t.eq({}, o.styles.functions, 'other styles keep defaults')
end)

t.test('extend does not change defaults', function()
  config.extend { styles = { keywords = { italic = true } }, integrations = { mini = false } }
  t.eq({ bold = true }, config.defaults.styles.keywords)
  t.eq({}, config.defaults.integrations)
end)

t.test('extend with nil is the same as empty', function()
  t.eq(config.defaults, config.extend())
end)

config.extend()
```

- [ ] **Step 2: Run the tests to see them fail**

Run: `nvim --clean -l apple.nvim/tests/run.lua`
Expected: error `module 'apple.config' not found`.

- [ ] **Step 3: Implement config**

`apple.nvim/lua/apple/config.lua`:

```lua
-- Options for the apple colorscheme.
local M = {}

---@class AppleOptions
---@field flavor 'auto'|'dark'|'light' 'auto' follows 'background'
---@field styles table<string, vim.api.keyset.highlight> extra style per syntax kind
---@field integrations table<string, boolean> force an integration on or off
---@field on_highlights? fun(groups: table, palette: table) change groups before they are applied

---@type AppleOptions
M.defaults = {
  flavor = 'auto',
  styles = {
    comments = {},
    keywords = { bold = true },
    functions = {},
    strings = {},
  },
  integrations = {},
  on_highlights = nil,
}

---@type AppleOptions
M.options = vim.deepcopy(M.defaults)

-- Build the options from the defaults and the user table.
-- Tables under `styles` replace the default (so `keywords = {}` removes bold).
-- Everything else is deep-merged.
---@param opts? table
---@return AppleOptions
function M.extend(opts)
  opts = opts or {}
  local options = vim.tbl_deep_extend('force', vim.deepcopy(M.defaults), opts)
  for key, style in pairs(opts.styles or {}) do
    options.styles[key] = vim.deepcopy(style)
  end
  M.options = options
  return options
end

return M
```

- [ ] **Step 4: Run the tests to see them pass**

Run: `nvim --clean -l apple.nvim/tests/run.lua`
Expected: all pass, `26 passed, 0 failed`.

- [ ] **Step 5: Format and commit**

```bash
stylua apple.nvim
git add apple.nvim
git commit -m "Add apple config with defaults and extend()

Written by Claude"
```

---

### Task 4: Core groups (editor + syntax), loader and `:colorscheme apple`

**Files:**
- Create: `apple.nvim/lua/apple/groups/editor.lua`
- Create: `apple.nvim/lua/apple/groups/syntax.lua`
- Create: `apple.nvim/lua/apple/groups/init.lua` (core only; integrations added in Task 7)
- Create: `apple.nvim/lua/apple/init.lua`
- Create: `apple.nvim/colors/apple.lua`
- Create: `apple.nvim/tests/colorscheme_spec.lua`

**Interfaces:**
- Consumes: `apple.palette`, `apple.config`, `apple.util`.
- Produces:
  - Every `apple.groups.<name>` module returns `{ get = function(p, opts) -> table<string, hl> }`.
  - `require('apple.groups')` with `M.core: string[]` and `M.get(p, opts): table<string, hl>`.
  - `require('apple')` with `setup(opts?)` and `load()`.
  - Style rule: `opts.styles.comments` is merged into `Comment`; `opts.styles.keywords` into `Keyword` and `Statement`; `opts.styles.functions` into `Function`; `opts.styles.strings` into `String`.

- [ ] **Step 1: Write the failing colorscheme tests**

`apple.nvim/tests/colorscheme_spec.lua`:

```lua
local t = require 'helpers'
local palette = require 'apple.palette'
local config = require 'apple.config'

-- Final highlight definition of a group (links resolved).
local function hl(name)
  return vim.api.nvim_get_hl(0, { name = name, link = false })
end

-- Review focus 1: no setup() call, defaults are used.
t.test('colorscheme apple loads without setup()', function()
  config.extend()
  vim.o.background = 'dark'
  local ok, err = pcall(vim.cmd.colorscheme, 'apple')
  t.ok(ok, tostring(err))
  t.eq('apple', vim.g.colors_name)
  t.eq(palette.dark.bg, t.hex(hl('Normal').bg))
end)

for _, mode in ipairs { 'dark', 'light' } do
  local p = palette[mode]

  t.test(mode .. ': loads and sets Normal from the palette', function()
    config.extend()
    vim.o.background = mode
    vim.cmd.colorscheme 'apple'
    t.eq('apple', vim.g.colors_name)
    t.eq(mode, vim.o.background, 'auto mode does not change background')
    t.eq(p.bg, t.hex(hl('Normal').bg), 'Normal bg')
    t.eq(p.fg, t.hex(hl('Normal').fg), 'Normal fg')
  end)

  t.test(mode .. ': Comment is gray and not italic by default', function()
    t.eq(p.comment, t.hex(hl('Comment').fg))
    t.eq(nil, hl('Comment').italic)
  end)

  t.test(mode .. ': syntax groups use Xcode-style colors', function()
    local expected = {
      Statement = p.pink,
      Keyword = p.pink,
      String = p.red,
      Number = p.yellow,
      Constant = p.yellow,
      Function = p.blue,
      Type = p.teal,
      PreProc = p.orange,
      Special = p.purple,
    }
    for group, color in pairs(expected) do
      t.eq(color, t.hex(hl(group).fg), group)
    end
    t.eq(true, hl('Keyword').bold, 'Keyword bold by default')
  end)

  t.test(mode .. ': diagnostics use red, orange, blue, gray, green', function()
    t.eq(p.red, t.hex(hl('DiagnosticError').fg))
    t.eq(p.orange, t.hex(hl('DiagnosticWarn').fg))
    t.eq(p.blue, t.hex(hl('DiagnosticInfo').fg))
    t.eq(p.comment, t.hex(hl('DiagnosticHint').fg))
    t.eq(p.green, t.hex(hl('DiagnosticOk').fg))
    t.eq(true, hl('DiagnosticUnderlineError').undercurl)
  end)

  t.test(mode .. ': search, selection and diff use the palette', function()
    t.eq(p.search, t.hex(hl('Search').bg))
    t.eq(p.cur_search, t.hex(hl('CurSearch').bg))
    t.eq(p.selection, t.hex(hl('Visual').bg))
    t.eq(p.diff_add_bg, t.hex(hl('DiffAdd').bg))
    t.eq(p.diff_delete_bg, t.hex(hl('DiffDelete').bg))
    t.eq(p.diff_text_bg, t.hex(hl('DiffText').bg))
  end)

  t.test(mode .. ': terminal colors are set', function()
    for i = 0, 15 do
      t.eq(p.terminal[i + 1], vim.g['terminal_color_' .. i], 'terminal_color_' .. i)
    end
  end)

  t.test(mode .. ': status line and popup menu use bg_alt', function()
    t.eq(p.bg_alt, t.hex(hl('StatusLine').bg))
    t.eq(p.bg_alt, t.hex(hl('Pmenu').bg))
    t.eq(p.selection, t.hex(hl('PmenuSel').bg))
    t.eq(p.bg_alt, t.hex(hl('NormalFloat').bg))
    t.eq(p.border, t.hex(hl('FloatBorder').fg))
  end)
end

t.test('styles: comments italic and keywords plain when asked', function()
  require('apple').setup { styles = { comments = { italic = true }, keywords = {} } }
  vim.o.background = 'dark'
  vim.cmd.colorscheme 'apple'
  t.eq(true, hl('Comment').italic)
  t.eq(nil, hl('Keyword').bold)
  t.eq(nil, hl('Statement').bold)
  config.extend()
end)

t.test('styles: functions and strings accept styles', function()
  require('apple').setup { styles = { functions = { italic = true }, strings = { bold = true } } }
  vim.cmd.colorscheme 'apple'
  t.eq(true, hl('Function').italic)
  t.eq(true, hl('String').bold)
  config.extend()
end)

t.test('every core group has valid keys and colors', function()
  config.extend()
  local groups = require('apple.groups').get(palette.dark, config.options)
  local valid = { fg = 1, bg = 1, sp = 1, bold = 1, italic = 1, underline = 1, undercurl = 1, strikethrough = 1, reverse = 1, link = 1, blend = 1, nocombine = 1, default = 1 }
  for name, def in pairs(groups) do
    for key, value in pairs(def) do
      t.ok(valid[key], name .. ' has unknown key ' .. key)
      if key == 'fg' or key == 'bg' or key == 'sp' then t.ok(value == 'NONE' or value:match '^#%x%x%x%x%x%x$', name .. '.' .. key .. ' = ' .. tostring(value)) end
    end
  end
end)
```

- [ ] **Step 2: Run the tests to see them fail**

Run: `nvim --clean -l apple.nvim/tests/run.lua`
Expected: `colorscheme apple loads` fails with `Cannot find color scheme 'apple'`.

- [ ] **Step 3: Create the editor groups**

`apple.nvim/lua/apple/groups/editor.lua`:

```lua
-- Highlight groups for the editor UI: windows, menus, status line, diff, spelling.
local M = {}

---@param p table palette
---@param _ table options (unused here)
function M.get(p, _)
  return {
    -- Windows and text
    Normal = { fg = p.fg, bg = p.bg },
    NormalNC = { fg = p.fg, bg = p.bg },
    NormalFloat = { fg = p.fg, bg = p.bg_alt },
    FloatBorder = { fg = p.border, bg = p.bg_alt },
    FloatTitle = { fg = p.fg, bg = p.bg_alt, bold = true },
    FloatFooter = { fg = p.comment, bg = p.bg_alt },
    FloatShadow = { bg = p.border, blend = 80 },
    FloatShadowThrough = { bg = p.border, blend = 100 },
    WinSeparator = { fg = p.border },
    EndOfBuffer = { fg = p.bg },
    NonText = { fg = p.border },
    Whitespace = { fg = p.border },
    SpecialKey = { fg = p.border },
    Conceal = { fg = p.comment },
    Directory = { fg = p.blue },
    Title = { fg = p.fg, bold = true },
    Underlined = { underline = true },

    -- Cursor and lines
    Cursor = { fg = p.bg, bg = p.cursor },
    lCursor = { fg = p.bg, bg = p.cursor },
    CursorIM = { fg = p.bg, bg = p.cursor },
    TermCursor = { fg = p.bg, bg = p.cursor },
    CursorLine = { bg = p.bg_alt },
    CursorColumn = { bg = p.bg_alt },
    ColorColumn = { bg = p.bg_alt },
    CursorLineNr = { fg = p.fg, bold = true },
    CursorLineSign = { bg = p.none },
    CursorLineFold = { fg = p.line_nr, bg = p.none },
    LineNr = { fg = p.line_nr },
    LineNrAbove = { fg = p.line_nr },
    LineNrBelow = { fg = p.line_nr },
    SignColumn = { fg = p.line_nr, bg = p.none },
    FoldColumn = { fg = p.line_nr, bg = p.none },
    Folded = { fg = p.comment, bg = p.bg_alt },
    MatchParen = { bg = p.border, bold = true },

    -- Selection and search
    Visual = { fg = p.selection_fg, bg = p.selection },
    VisualNOS = { fg = p.selection_fg, bg = p.selection },
    Search = { fg = p.search_fg, bg = p.search },
    CurSearch = { fg = p.search_fg, bg = p.cur_search },
    IncSearch = { fg = p.search_fg, bg = p.cur_search },
    Substitute = { fg = p.search_fg, bg = p.cur_search },

    -- Popup menu and wild menu
    Pmenu = { fg = p.fg, bg = p.bg_alt },
    PmenuSel = { fg = p.selection_fg, bg = p.selection },
    PmenuKind = { fg = p.teal, bg = p.bg_alt },
    PmenuKindSel = { fg = p.selection_fg, bg = p.selection },
    PmenuExtra = { fg = p.comment, bg = p.bg_alt },
    PmenuExtraSel = { fg = p.selection_fg, bg = p.selection },
    PmenuMatch = { fg = p.blue, bg = p.bg_alt, bold = true },
    PmenuMatchSel = { fg = p.selection_fg, bg = p.selection, bold = true },
    PmenuSbar = { bg = p.bg_alt },
    PmenuThumb = { bg = p.border },
    WildMenu = { fg = p.selection_fg, bg = p.selection },
    ComplMatchIns = { fg = p.comment },

    -- Status line, win bar, tab line
    StatusLine = { fg = p.fg, bg = p.bg_alt },
    StatusLineNC = { fg = p.comment, bg = p.bg_alt },
    StatusLineTerm = { fg = p.fg, bg = p.bg_alt },
    StatusLineTermNC = { fg = p.comment, bg = p.bg_alt },
    WinBar = { fg = p.fg, bg = p.bg_alt, bold = true },
    WinBarNC = { fg = p.comment, bg = p.bg_alt },
    TabLine = { fg = p.comment, bg = p.bg_alt },
    TabLineSel = { fg = p.fg, bg = p.bg, bold = true },
    TabLineFill = { bg = p.bg_alt },

    -- Messages
    ErrorMsg = { fg = p.red },
    WarningMsg = { fg = p.orange },
    ModeMsg = { fg = p.fg, bold = true },
    MoreMsg = { fg = p.green },
    OkMsg = { fg = p.green },
    Question = { fg = p.blue },
    MsgArea = { fg = p.fg },
    MsgSeparator = { fg = p.border, bg = p.bg_alt },
    QuickFixLine = { bg = p.bg_alt, bold = true },
    qfLineNr = { fg = p.line_nr },
    qfFileName = { fg = p.blue },
    NvimInternalError = { fg = p.bg, bg = p.red },

    -- Diff
    DiffAdd = { bg = p.diff_add_bg },
    DiffChange = { bg = p.diff_change_bg },
    DiffDelete = { fg = p.red, bg = p.diff_delete_bg },
    DiffText = { bg = p.diff_text_bg },
    Added = { fg = p.green },
    Changed = { fg = p.blue },
    Removed = { fg = p.red },

    -- Spelling
    SpellBad = { undercurl = true, sp = p.red },
    SpellCap = { undercurl = true, sp = p.blue },
    SpellRare = { undercurl = true, sp = p.purple },
    SpellLocal = { undercurl = true, sp = p.teal },

    -- Misc
    SnippetTabstop = { bg = p.bg_alt },
    healthError = { fg = p.red },
    healthSuccess = { fg = p.green },
    healthWarning = { fg = p.orange },
    RedrawDebugClear = { bg = p.search },
    RedrawDebugComposed = { bg = p.diff_add_bg },
    RedrawDebugRecompose = { bg = p.diff_delete_bg },
  }
end

return M
```

- [ ] **Step 4: Create the syntax groups**

`apple.nvim/lua/apple/groups/syntax.lua`:

```lua
-- Highlight groups for Vim syntax (Xcode-style colors) and diagnostics.
local M = {}

-- Merge a user style into a base definition. The user style wins.
local function style(base, extra)
  return vim.tbl_extend('force', base, extra or {})
end

---@param p table palette
---@param opts table options
function M.get(p, opts)
  local s = opts.styles or {}
  return {
    -- Syntax
    Comment = style({ fg = p.comment }, s.comments),
    Constant = { fg = p.yellow },
    String = style({ fg = p.red }, s.strings),
    Character = { fg = p.red },
    Number = { fg = p.yellow },
    Boolean = { fg = p.yellow },
    Float = { fg = p.yellow },
    Identifier = { fg = p.fg },
    Function = style({ fg = p.blue }, s.functions),
    Statement = style({ fg = p.pink }, s.keywords),
    Conditional = { link = 'Statement' },
    Repeat = { link = 'Statement' },
    Label = { link = 'Statement' },
    Operator = { fg = p.fg },
    Keyword = style({ fg = p.pink }, s.keywords),
    Exception = { link = 'Statement' },
    PreProc = { fg = p.orange },
    Include = { link = 'PreProc' },
    Define = { link = 'PreProc' },
    Macro = { link = 'PreProc' },
    PreCondit = { link = 'PreProc' },
    Type = { fg = p.teal },
    StorageClass = { link = 'Type' },
    Structure = { link = 'Type' },
    Typedef = { link = 'Type' },
    Special = { fg = p.purple },
    SpecialChar = { fg = p.purple },
    Tag = { fg = p.blue },
    Delimiter = { fg = p.fg },
    SpecialComment = { fg = p.comment, bold = true },
    Debug = { fg = p.orange },
    Ignore = { fg = p.comment },
    Error = { fg = p.red, bold = true },
    Todo = { fg = p.purple, bold = true },

    -- Diagnostics
    DiagnosticError = { fg = p.red },
    DiagnosticWarn = { fg = p.orange },
    DiagnosticInfo = { fg = p.blue },
    DiagnosticHint = { fg = p.comment },
    DiagnosticOk = { fg = p.green },
    DiagnosticVirtualTextError = { fg = p.red, bg = p.none },
    DiagnosticVirtualTextWarn = { fg = p.orange, bg = p.none },
    DiagnosticVirtualTextInfo = { fg = p.blue, bg = p.none },
    DiagnosticVirtualTextHint = { fg = p.comment, bg = p.none },
    DiagnosticVirtualTextOk = { fg = p.green, bg = p.none },
    DiagnosticUnderlineError = { undercurl = true, sp = p.red },
    DiagnosticUnderlineWarn = { undercurl = true, sp = p.orange },
    DiagnosticUnderlineInfo = { undercurl = true, sp = p.blue },
    DiagnosticUnderlineHint = { undercurl = true, sp = p.comment },
    DiagnosticUnderlineOk = { undercurl = true, sp = p.green },
    DiagnosticFloatingError = { fg = p.red, bg = p.bg_alt },
    DiagnosticFloatingWarn = { fg = p.orange, bg = p.bg_alt },
    DiagnosticFloatingInfo = { fg = p.blue, bg = p.bg_alt },
    DiagnosticFloatingHint = { fg = p.comment, bg = p.bg_alt },
    DiagnosticFloatingOk = { fg = p.green, bg = p.bg_alt },
    DiagnosticSignError = { fg = p.red },
    DiagnosticSignWarn = { fg = p.orange },
    DiagnosticSignInfo = { fg = p.blue },
    DiagnosticSignHint = { fg = p.comment },
    DiagnosticSignOk = { fg = p.green },
    DiagnosticDeprecated = { strikethrough = true, sp = p.comment },
    DiagnosticUnnecessary = { fg = p.comment },
  }
end

return M
```

- [ ] **Step 5: Create the groups merger (core only for now)**

`apple.nvim/lua/apple/groups/init.lua`:

```lua
-- Builds the full highlight table: core groups, then enabled integrations.
local util = require 'apple.util'

local M = {}

-- Always applied.
M.core = { 'editor', 'syntax' }

-- Applied when the plugin is found, or forced with opts.integrations.
-- Each module exports `detect` (module names for util.has_plugin) and `get`.
M.integrations = {}

-- Is this integration on? User option wins, then plugin detection.
---@param name string
---@param opts table
---@return boolean
function M.enabled(name, opts)
  local forced = (opts.integrations or {})[name]
  if forced ~= nil then return forced end
  return util.has_plugin(require('apple.groups.' .. name).detect)
end

-- Merge every group file into one table. Later files win.
---@param p table palette
---@param opts table options
---@return table<string, vim.api.keyset.highlight>
function M.get(p, opts)
  local groups = {}
  local function add(name)
    for group, def in pairs(require('apple.groups.' .. name).get(p, opts)) do
      groups[group] = def
    end
  end
  for _, name in ipairs(M.core) do
    add(name)
  end
  for _, name in ipairs(M.integrations) do
    if M.enabled(name, opts) then add(name) end
  end
  return groups
end

return M
```

- [ ] **Step 6: Create the loader**

`apple.nvim/lua/apple/init.lua`:

```lua
-- The "apple" colorscheme: Apple system colors for Neovim.
-- `setup()` stores options. `:colorscheme apple` (colors/apple.lua) calls `load()`.
local M = {}

-- True while load() runs. Setting 'background' inside load() makes Neovim
-- run `:colorscheme apple` again; this flag stops that second run.
local loading = false

-- Store options. Optional: `:colorscheme apple` works with defaults.
---@param opts? table see apple.config defaults
function M.setup(opts)
  require('apple.config').extend(opts)
end

-- Which palette to use: the option, or 'background' when the option is 'auto'.
---@return 'dark'|'light'
local function resolve_flavor(opts)
  if opts.flavor == 'dark' or opts.flavor == 'light' then return opts.flavor end
  return vim.o.background == 'light' and 'light' or 'dark'
end

local function do_load()
  local opts = require('apple.config').options
  local flavor = resolve_flavor(opts)

  -- A forced flavor also sets 'background', so plugins and Neovim agree.
  -- In 'auto' mode we never touch it, so the theme keeps following the terminal.
  if vim.o.background ~= flavor then vim.o.background = flavor end

  vim.cmd 'highlight clear'
  vim.g.colors_name = 'apple'

  local palette = require('apple.palette')[flavor]
  local groups = require('apple.groups').get(palette, opts)
  if opts.on_highlights then opts.on_highlights(groups, palette) end

  require('apple.util').apply(groups)
  for i, color in ipairs(palette.terminal) do
    vim.g['terminal_color_' .. (i - 1)] = color
  end
end

-- Apply the colorscheme for the current options and 'background'.
function M.load()
  if loading then return end
  loading = true
  local ok, err = pcall(do_load)
  loading = false
  if not ok then error(err, 0) end
end

return M
```

- [ ] **Step 7: Create the colorscheme entry point**

`apple.nvim/colors/apple.lua`:

```lua
-- Entry point for `:colorscheme apple`. The code is in lua/apple/.
require('apple').load()
```

- [ ] **Step 8: Run the tests to see them pass**

Run: `nvim --clean -l apple.nvim/tests/run.lua`
Expected: all pass, exit 0. If a `valid keys` failure appears, fix the group definition it names.

- [ ] **Step 9: Try it by eye**

Run: `nvim --clean --cmd 'set rtp^=apple.nvim' -c 'colorscheme apple' apple.nvim/lua/apple/init.lua`
Expected: dark theme, pink bold keywords, red strings, blue function names. Then `:set background=light` switches to the light palette. `:q` to exit.

- [ ] **Step 10: Format and commit**

```bash
stylua apple.nvim
git add apple.nvim
git commit -m "Add apple core highlight groups and colorscheme loader

Written by Claude"
```

---

### Task 5: Treesitter and LSP groups

**Files:**
- Create: `apple.nvim/lua/apple/groups/treesitter.lua`
- Create: `apple.nvim/lua/apple/groups/lsp.lua`
- Modify: `apple.nvim/lua/apple/groups/init.lua` (add to `M.core`)
- Modify: `apple.nvim/tests/colorscheme_spec.lua` (append tests)

**Interfaces:**
- Consumes: group module contract from Task 4.
- Produces: `M.core = { 'editor', 'syntax', 'treesitter', 'lsp' }`. Treesitter captures follow the syntax colors; `@keyword.*` get `opts.styles.keywords`, `@comment` gets `opts.styles.comments`, `@function.*` gets `opts.styles.functions`, `@string` gets `opts.styles.strings`.

- [ ] **Step 1: Append failing tests**

Add to the end of `apple.nvim/tests/colorscheme_spec.lua`:

```lua
for _, mode in ipairs { 'dark', 'light' } do
  local p = palette[mode]

  t.test(mode .. ': treesitter captures follow the Xcode colors', function()
    config.extend()
    vim.o.background = mode
    vim.cmd.colorscheme 'apple'
    t.eq(p.fg, t.hex(hl('@variable').fg), '@variable')
    t.eq(p.purple, t.hex(hl('@variable.builtin').fg), '@variable.builtin')
    t.eq(p.pink, t.hex(hl('@keyword').fg), '@keyword')
    t.eq(true, hl('@keyword').bold, '@keyword bold')
    t.eq(p.pink, t.hex(hl('@keyword.return').fg), '@keyword.return')
    t.eq(p.blue, t.hex(hl('@function').fg), '@function')
    t.eq(p.blue, t.hex(hl('@function.method').fg), '@function.method')
    t.eq(p.teal, t.hex(hl('@type').fg), '@type')
    t.eq(p.red, t.hex(hl('@string').fg), '@string')
    t.eq(p.purple, t.hex(hl('@string.escape').fg), '@string.escape')
    t.eq(p.yellow, t.hex(hl('@number').fg), '@number')
    t.eq(p.orange, t.hex(hl('@keyword.import').fg), '@keyword.import')
    t.eq(p.comment, t.hex(hl('@comment').fg), '@comment')
    t.eq(p.fg, t.hex(hl('@punctuation.delimiter').fg), '@punctuation.delimiter')
  end)

  t.test(mode .. ': markup captures for markdown and help', function()
    t.eq(true, hl('@markup.strong').bold)
    t.eq(true, hl('@markup.italic').italic)
    t.eq(p.blue, t.hex(hl('@markup.heading').fg))
    t.eq(p.blue, t.hex(hl('@markup.link.url').fg))
    t.eq(true, hl('@markup.link.url').underline)
    t.eq(p.green, t.hex(hl('@diff.plus').fg))
    t.eq(p.red, t.hex(hl('@diff.minus').fg))
  end)

  t.test(mode .. ': LSP semantic tokens and references', function()
    t.eq(p.teal, t.hex(hl('@lsp.type.class').fg), '@lsp.type.class')
    t.eq(p.fg, t.hex(hl('@lsp.type.variable').fg), '@lsp.type.variable')
    t.eq(p.blue, t.hex(hl('@lsp.type.function').fg), '@lsp.type.function')
    t.eq(true, hl('@lsp.mod.deprecated').strikethrough, '@lsp.mod.deprecated')
    t.eq(p.bg_alt, t.hex(hl('LspReferenceText').bg), 'LspReferenceText')
    t.eq(p.comment, t.hex(hl('LspInlayHint').fg), 'LspInlayHint')
    t.eq(p.bg_alt, t.hex(hl('LspInlayHint').bg), 'LspInlayHint bg')
    t.eq(true, hl('LspSignatureActiveParameter').bold)
  end)
end

t.test('styles apply to treesitter captures too', function()
  require('apple').setup { styles = { comments = { italic = true }, keywords = {}, functions = { italic = true }, strings = { bold = true } } }
  vim.cmd.colorscheme 'apple'
  t.eq(true, hl('@comment').italic)
  t.eq(nil, hl('@keyword').bold)
  t.eq(nil, hl('@keyword.function').bold)
  t.eq(true, hl('@function').italic)
  t.eq(true, hl('@string').bold)
  config.extend()
end)
```

- [ ] **Step 2: Run the tests to see them fail**

Run: `nvim --clean -l apple.nvim/tests/run.lua`
Expected: the treesitter and LSP tests fail, e.g. `@keyword.import: expected "#FFA056", got ...` and `LspInlayHint bg: expected "#2C2C2E", got nil`.

- [ ] **Step 3: Create the treesitter groups**

`apple.nvim/lua/apple/groups/treesitter.lua`:

```lua
-- Highlight groups for treesitter captures (see :help treesitter-highlight-groups).
-- Most captures follow the Xcode-style colors from syntax.lua.
local M = {}

local function style(base, extra)
  return vim.tbl_extend('force', base, extra or {})
end

---@param p table palette
---@param opts table options
function M.get(p, opts)
  local s = opts.styles or {}
  local keyword = style({ fg = p.pink }, s.keywords)
  local func = style({ fg = p.blue }, s.functions)

  return {
    -- Identifiers
    ['@variable'] = { fg = p.fg },
    ['@variable.builtin'] = { fg = p.purple },
    ['@variable.parameter'] = { fg = p.fg },
    ['@variable.parameter.builtin'] = { fg = p.purple },
    ['@variable.member'] = { fg = p.fg },
    ['@constant'] = { fg = p.yellow },
    ['@constant.builtin'] = { fg = p.yellow },
    ['@constant.macro'] = { fg = p.orange },
    ['@module'] = { fg = p.teal },
    ['@module.builtin'] = { fg = p.purple },
    ['@label'] = { fg = p.pink },

    -- Literals
    ['@string'] = style({ fg = p.red }, s.strings),
    ['@string.documentation'] = { fg = p.comment },
    ['@string.regexp'] = { fg = p.orange },
    ['@string.escape'] = { fg = p.purple },
    ['@string.special'] = { fg = p.purple },
    ['@string.special.symbol'] = { fg = p.yellow },
    ['@string.special.path'] = { fg = p.blue, underline = true },
    ['@string.special.url'] = { fg = p.blue, underline = true },
    ['@character'] = { fg = p.red },
    ['@character.special'] = { fg = p.purple },
    ['@boolean'] = { fg = p.yellow },
    ['@number'] = { fg = p.yellow },
    ['@number.float'] = { fg = p.yellow },

    -- Types
    ['@type'] = { fg = p.teal },
    ['@type.builtin'] = { fg = p.teal },
    ['@type.definition'] = { fg = p.teal },
    ['@attribute'] = { fg = p.orange },
    ['@attribute.builtin'] = { fg = p.orange },
    ['@property'] = { fg = p.fg },

    -- Functions
    ['@function'] = func,
    ['@function.builtin'] = func,
    ['@function.call'] = func,
    ['@function.macro'] = style({ fg = p.orange }, s.functions),
    ['@function.method'] = func,
    ['@function.method.call'] = func,
    ['@constructor'] = { fg = p.teal },
    ['@operator'] = { fg = p.fg },

    -- Keywords
    ['@keyword'] = keyword,
    ['@keyword.coroutine'] = keyword,
    ['@keyword.function'] = keyword,
    ['@keyword.operator'] = keyword,
    ['@keyword.import'] = style({ fg = p.orange }, s.keywords),
    ['@keyword.type'] = keyword,
    ['@keyword.modifier'] = keyword,
    ['@keyword.repeat'] = keyword,
    ['@keyword.return'] = keyword,
    ['@keyword.debug'] = keyword,
    ['@keyword.exception'] = keyword,
    ['@keyword.conditional'] = keyword,
    ['@keyword.conditional.ternary'] = { fg = p.fg },
    ['@keyword.directive'] = style({ fg = p.orange }, s.keywords),
    ['@keyword.directive.define'] = style({ fg = p.orange }, s.keywords),

    -- Punctuation
    ['@punctuation.delimiter'] = { fg = p.fg },
    ['@punctuation.bracket'] = { fg = p.fg },
    ['@punctuation.special'] = { fg = p.purple },

    -- Comments
    ['@comment'] = style({ fg = p.comment }, s.comments),
    ['@comment.documentation'] = style({ fg = p.comment }, s.comments),
    ['@comment.error'] = { fg = p.red, bold = true },
    ['@comment.warning'] = { fg = p.orange, bold = true },
    ['@comment.todo'] = { fg = p.purple, bold = true },
    ['@comment.note'] = { fg = p.blue, bold = true },

    -- Markup (markdown, help, ...)
    ['@markup.strong'] = { bold = true },
    ['@markup.italic'] = { italic = true },
    ['@markup.strikethrough'] = { strikethrough = true },
    ['@markup.underline'] = { underline = true },
    ['@markup.heading'] = { fg = p.blue, bold = true },
    ['@markup.heading.1'] = { fg = p.blue, bold = true },
    ['@markup.heading.2'] = { fg = p.teal, bold = true },
    ['@markup.heading.3'] = { fg = p.green, bold = true },
    ['@markup.heading.4'] = { fg = p.yellow, bold = true },
    ['@markup.heading.5'] = { fg = p.orange, bold = true },
    ['@markup.heading.6'] = { fg = p.pink, bold = true },
    ['@markup.quote'] = { fg = p.comment },
    ['@markup.math'] = { fg = p.yellow },
    ['@markup.link'] = { fg = p.blue },
    ['@markup.link.label'] = { fg = p.purple },
    ['@markup.link.url'] = { fg = p.blue, underline = true },
    ['@markup.raw'] = { fg = p.red },
    ['@markup.raw.block'] = { fg = p.fg },
    ['@markup.list'] = { fg = p.purple },
    ['@markup.list.checked'] = { fg = p.green },
    ['@markup.list.unchecked'] = { fg = p.comment },

    -- Diff and tags
    ['@diff.plus'] = { fg = p.green },
    ['@diff.minus'] = { fg = p.red },
    ['@diff.delta'] = { fg = p.blue },
    ['@tag'] = { fg = p.blue },
    ['@tag.builtin'] = { fg = p.blue },
    ['@tag.attribute'] = { fg = p.teal },
    ['@tag.delimiter'] = { fg = p.fg },
  }
end

return M
```

- [ ] **Step 4: Create the LSP groups**

`apple.nvim/lua/apple/groups/lsp.lua`:

```lua
-- Highlight groups for the built-in LSP client: semantic tokens, references, inlay hints.
local M = {}

---@param p table palette
---@param _ table options (unused here)
function M.get(p, _)
  return {
    -- Semantic tokens link to the treesitter captures with the same meaning.
    ['@lsp.type.class'] = { link = '@type' },
    ['@lsp.type.comment'] = { link = '@comment' },
    ['@lsp.type.decorator'] = { link = '@attribute' },
    ['@lsp.type.enum'] = { link = '@type' },
    ['@lsp.type.enumMember'] = { link = '@constant' },
    ['@lsp.type.event'] = { link = '@type' },
    ['@lsp.type.function'] = { link = '@function' },
    ['@lsp.type.interface'] = { link = '@type' },
    ['@lsp.type.keyword'] = { link = '@keyword' },
    ['@lsp.type.macro'] = { link = '@function.macro' },
    ['@lsp.type.method'] = { link = '@function.method' },
    ['@lsp.type.modifier'] = { link = '@keyword.modifier' },
    ['@lsp.type.namespace'] = { link = '@module' },
    ['@lsp.type.number'] = { link = '@number' },
    ['@lsp.type.operator'] = { link = '@operator' },
    ['@lsp.type.parameter'] = { link = '@variable.parameter' },
    ['@lsp.type.property'] = { link = '@property' },
    ['@lsp.type.regexp'] = { link = '@string.regexp' },
    ['@lsp.type.string'] = { link = '@string' },
    ['@lsp.type.struct'] = { link = '@type' },
    ['@lsp.type.type'] = { link = '@type' },
    ['@lsp.type.typeParameter'] = { link = '@type' },
    ['@lsp.type.variable'] = { link = '@variable' },
    ['@lsp.mod.deprecated'] = { strikethrough = true },
    ['@lsp.typemod.variable.readonly'] = { link = '@constant' },
    ['@lsp.typemod.variable.defaultLibrary'] = { link = '@variable.builtin' },
    ['@lsp.typemod.function.defaultLibrary'] = { link = '@function.builtin' },

    -- References and hints
    LspReferenceText = { bg = p.bg_alt },
    LspReferenceRead = { bg = p.bg_alt },
    LspReferenceWrite = { bg = p.bg_alt, underline = true },
    LspReferenceTarget = { bg = p.bg_alt },
    LspInlayHint = { fg = p.comment, bg = p.bg_alt },
    LspCodeLens = { fg = p.comment },
    LspCodeLensSeparator = { fg = p.border },
    LspSignatureActiveParameter = { bg = p.border, bold = true },
  }
end

return M
```

- [ ] **Step 5: Register both files as core**

In `apple.nvim/lua/apple/groups/init.lua` change:

```lua
M.core = { 'editor', 'syntax', 'treesitter', 'lsp' }
```

- [ ] **Step 6: Run the tests to see them pass**

Run: `nvim --clean -l apple.nvim/tests/run.lua`
Expected: all pass, exit 0.

- [ ] **Step 7: Format and commit**

```bash
stylua apple.nvim
git add apple.nvim
git commit -m "Add treesitter and LSP highlight groups

Written by Claude"
```

---

### Task 6: Flavor forcing, background switching and `on_highlights`

**Files:**
- Modify: `apple.nvim/tests/colorscheme_spec.lua` (append tests)
- Modify: `apple.nvim/lua/apple/init.lua` only if a test fails (the Task 4 loader is designed to pass these)

**Interfaces:**
- Consumes: `require('apple').setup/load`, `config.extend`.
- Produces: verified behavior: `flavor = 'dark'|'light'` sets `background`; `auto` follows `background` changes; `on_highlights(groups, palette)` can change or add groups; a failing `on_highlights` does not break later loads.

- [ ] **Step 1: Append failing tests**

Add to the end of `apple.nvim/tests/colorscheme_spec.lua`:

```lua
t.test('flavor = light forces background and palette', function()
  require('apple').setup { flavor = 'light' }
  vim.o.background = 'dark'
  vim.cmd.colorscheme 'apple'
  t.eq('light', vim.o.background)
  t.eq(palette.light.bg, t.hex(hl('Normal').bg))
  t.eq('apple', vim.g.colors_name)
  config.extend()
end)

t.test('flavor = dark wins when the terminal switches background', function()
  require('apple').setup { flavor = 'dark' }
  vim.o.background = 'dark'
  vim.cmd.colorscheme 'apple'
  -- Neovim reloads the colorscheme on this change; the theme sets it back.
  vim.o.background = 'light'
  t.eq('dark', vim.o.background)
  t.eq(palette.dark.bg, t.hex(hl('Normal').bg))
  config.extend()
end)

-- Review focus 3: auto mode follows a background change at runtime.
t.test('auto flavor follows background changes after load', function()
  config.extend()
  vim.o.background = 'dark'
  vim.cmd.colorscheme 'apple'
  vim.o.background = 'light'
  t.eq('apple', vim.g.colors_name)
  t.eq(palette.light.bg, t.hex(hl('Normal').bg))
  vim.o.background = 'dark'
  t.eq(palette.dark.bg, t.hex(hl('Normal').bg))
end)

t.test('on_highlights can change and add groups', function()
  require('apple').setup {
    on_highlights = function(groups, p)
      groups.Comment = { fg = p.blue }
      groups.AppleCustom = { fg = p.green, bold = true }
    end,
  }
  vim.cmd.colorscheme 'apple'
  t.eq(palette.dark.blue, t.hex(hl('Comment').fg))
  t.eq(palette.dark.green, t.hex(hl('AppleCustom').fg))
  t.eq(true, hl('AppleCustom').bold)
  config.extend()
end)

-- Review focus 4: an error in on_highlights must not block the next load.
t.test('a failing on_highlights does not break the next load', function()
  require('apple').setup {
    on_highlights = function()
      error 'boom'
    end,
  }
  local ok = pcall(vim.cmd.colorscheme, 'apple')
  t.eq(false, ok, 'error is reported')
  config.extend()
  local ok2, err = pcall(vim.cmd.colorscheme, 'apple')
  t.ok(ok2, tostring(err))
  t.eq(palette.dark.bg, t.hex(hl('Normal').bg))
end)
```

- [ ] **Step 2: Run the tests**

Run: `nvim --clean -l apple.nvim/tests/run.lua`
Expected: all pass. The Task 4 loader already implements this behavior. If `flavor = dark wins` fails because Neovim did not reload the colorscheme on `background` change, check that `vim.g.colors_name` is `'apple'` before the change (Neovim only reloads when `colors_name` is set).

- [ ] **Step 3: Commit**

```bash
stylua apple.nvim
git add apple.nvim
git commit -m "Test flavor forcing, background switching and on_highlights

Written by Claude"
```

---

### Task 7: Integration mechanism with the first integration (telescope)

**Files:**
- Create: `apple.nvim/lua/apple/groups/telescope.lua`
- Create: `apple.nvim/tests/integrations_spec.lua`
- Modify: `apple.nvim/lua/apple/groups/init.lua` (`M.integrations`)

**Interfaces:**
- Consumes: `groups.enabled(name, opts)`, `util.has_plugin`.
- Produces: integration module contract: `{ detect = string | string[], get = function(p, opts) }`. `M.integrations = { 'telescope' }` (extended in Tasks 8-10). The generic test in `integrations_spec.lua` checks **every** name in `M.integrations`, so later tasks only add a small specific test each.

- [ ] **Step 1: Write the failing integration tests**

`apple.nvim/tests/integrations_spec.lua`:

```lua
local t = require 'helpers'
local palette = require 'apple.palette'
local config = require 'apple.config'
local groups = require 'apple.groups'

local function hl(name)
  return vim.api.nvim_get_hl(0, { name = name, link = false })
end

local valid = { fg = 1, bg = 1, sp = 1, bold = 1, italic = 1, underline = 1, undercurl = 1, strikethrough = 1, reverse = 1, link = 1, blend = 1, nocombine = 1, default = 1 }

t.test('integration list has the expected names', function()
  t.ok(vim.tbl_contains(groups.integrations, 'telescope'), 'telescope is listed')
end)

-- Generic checks for every integration file.
for _, name in ipairs(groups.integrations) do
  local mod = require('apple.groups.' .. name)

  t.test(name .. ': has detect and get', function()
    t.ok(type(mod.detect) == 'string' or type(mod.detect) == 'table', 'detect')
    t.eq('function', type(mod.get))
  end)

  for _, mode in ipairs { 'dark', 'light' } do
    t.test(name .. ' (' .. mode .. '): returns valid highlight definitions', function()
      local defs = mod.get(palette[mode], config.defaults)
      t.ok(next(defs) ~= nil, 'not empty')
      for group, def in pairs(defs) do
        t.eq('table', type(def), group)
        for key, value in pairs(def) do
          t.ok(valid[key], group .. ' has unknown key ' .. key)
          if key == 'fg' or key == 'bg' or key == 'sp' then t.ok(value == 'NONE' or value:match '^#%x%x%x%x%x%x$', group .. '.' .. key .. ' = ' .. tostring(value)) end
        end
      end
    end)
  end

  t.test(name .. ': is off when the plugin is missing (nvim --clean)', function()
    t.eq(false, groups.enabled(name, config.defaults))
  end)

  t.test(name .. ': can be forced on', function()
    t.eq(true, groups.enabled(name, { integrations = { [name] = true } }))
  end)
end

t.test('forced integration groups are applied by :colorscheme', function()
  require('apple').setup { integrations = { telescope = true } }
  vim.o.background = 'dark'
  vim.cmd.colorscheme 'apple'
  t.eq(palette.dark.bg_alt, t.hex(hl('TelescopeNormal').bg))
  config.extend()
end)

t.test('integration set to false is not applied', function()
  require('apple').setup { integrations = { telescope = false } }
  vim.cmd 'highlight clear'
  vim.cmd.colorscheme 'apple'
  local def = vim.api.nvim_get_hl(0, { name = 'TelescopeNormal' })
  t.eq(true, vim.tbl_isempty(def), 'TelescopeNormal is not defined')
  config.extend()
end)

t.test('a loaded module turns the integration on', function()
  package.loaded['telescope'] = {}
  t.eq(true, groups.enabled('telescope', config.defaults))
  package.loaded['telescope'] = nil
end)

-- Review focus 5: unknown integration names are ignored.
t.test('unknown integration names are ignored', function()
  require('apple').setup { integrations = { not_a_real_plugin = true } }
  local ok, err = pcall(vim.cmd.colorscheme, 'apple')
  t.ok(ok, tostring(err))
  config.extend()
end)
```

- [ ] **Step 2: Run the tests to see them fail**

Run: `nvim --clean -l apple.nvim/tests/run.lua`
Expected: `integration list has the expected names` fails; `forced integration groups are applied` fails (`TelescopeNormal` has no bg).

- [ ] **Step 3: Create the telescope groups**

`apple.nvim/lua/apple/groups/telescope.lua`:

```lua
-- telescope.nvim: floating picker windows.
local M = {}

M.detect = 'telescope'

---@param p table palette
---@param _ table options (unused here)
function M.get(p, _)
  return {
    TelescopeNormal = { fg = p.fg, bg = p.bg_alt },
    TelescopeBorder = { fg = p.border, bg = p.bg_alt },
    TelescopeTitle = { fg = p.fg, bg = p.bg_alt, bold = true },
    TelescopePromptNormal = { fg = p.fg, bg = p.bg_alt },
    TelescopePromptBorder = { fg = p.border, bg = p.bg_alt },
    TelescopePromptTitle = { fg = p.bg, bg = p.blue, bold = true },
    TelescopePromptPrefix = { fg = p.blue, bg = p.bg_alt },
    TelescopePromptCounter = { fg = p.comment, bg = p.bg_alt },
    TelescopeResultsTitle = { fg = p.comment, bg = p.bg_alt },
    TelescopePreviewTitle = { fg = p.bg, bg = p.green, bold = true },
    TelescopeSelection = { fg = p.selection_fg, bg = p.selection },
    TelescopeSelectionCaret = { fg = p.selection_fg, bg = p.selection },
    TelescopeMultiSelection = { fg = p.purple, bg = p.bg_alt },
    TelescopeMultiIcon = { fg = p.purple },
    TelescopeMatching = { fg = p.blue, bold = true },
    TelescopeResultsComment = { fg = p.comment },
    TelescopeResultsDiffAdd = { fg = p.green },
    TelescopeResultsDiffChange = { fg = p.blue },
    TelescopeResultsDiffDelete = { fg = p.red },
    TelescopeResultsDiffUntracked = { fg = p.orange },
    TelescopePreviewLine = { bg = p.border },
    TelescopePreviewMatch = { fg = p.search_fg, bg = p.search },
  }
end

return M
```

- [ ] **Step 4: Register the integration**

In `apple.nvim/lua/apple/groups/init.lua`:

```lua
M.integrations = { 'telescope' }
```

- [ ] **Step 5: Run the tests to see them pass**

Run: `nvim --clean -l apple.nvim/tests/run.lua`
Expected: all pass, exit 0.

- [ ] **Step 6: Format and commit**

```bash
stylua apple.nvim
git add apple.nvim
git commit -m "Add integration detection and telescope groups

Written by Claude"
```

---

### Task 8: Integrations: blink.cmp, gitsigns, which-key, todo-comments

**Files:**
- Create: `apple.nvim/lua/apple/groups/blink.lua`
- Create: `apple.nvim/lua/apple/groups/gitsigns.lua`
- Create: `apple.nvim/lua/apple/groups/which_key.lua`
- Create: `apple.nvim/lua/apple/groups/todo_comments.lua`
- Modify: `apple.nvim/lua/apple/groups/init.lua` (`M.integrations`)
- Modify: `apple.nvim/tests/integrations_spec.lua` (append)

**Interfaces:**
- Consumes: integration module contract from Task 7.
- Produces: `M.integrations = { 'telescope', 'blink', 'gitsigns', 'which_key', 'todo_comments' }`.

- [ ] **Step 1: Append failing tests**

Add to the end of `apple.nvim/tests/integrations_spec.lua`:

```lua
t.test('blink, gitsigns, which_key, todo_comments are listed', function()
  for _, name in ipairs { 'blink', 'gitsigns', 'which_key', 'todo_comments' } do
    t.ok(vim.tbl_contains(groups.integrations, name), name)
  end
end)

t.test('blink: menu uses bg_alt, selection uses the selection color', function()
  local defs = require('apple.groups.blink').get(palette.dark, config.defaults)
  t.eq(palette.dark.bg_alt, defs.BlinkCmpMenu.bg)
  t.eq(palette.dark.selection, defs.BlinkCmpMenuSelection.bg)
  t.eq(palette.dark.blue, defs.BlinkCmpLabelMatch.fg)
  t.eq('blink.cmp', require('apple.groups.blink').detect)
end)

t.test('gitsigns: add/change/delete use green/blue/red', function()
  local defs = require('apple.groups.gitsigns').get(palette.light, config.defaults)
  t.eq(palette.light.green, defs.GitSignsAdd.fg)
  t.eq(palette.light.blue, defs.GitSignsChange.fg)
  t.eq(palette.light.red, defs.GitSignsDelete.fg)
  t.eq(palette.light.diff_add_bg, defs.GitSignsAddLn.bg)
end)

t.test('which_key: key is blue, group is teal', function()
  local defs = require('apple.groups.which_key').get(palette.dark, config.defaults)
  t.eq(palette.dark.blue, defs.WhichKey.fg)
  t.eq(palette.dark.teal, defs.WhichKeyGroup.fg)
  t.eq('which-key', require('apple.groups.which_key').detect)
end)

t.test('todo_comments: keyword colors follow diagnostics', function()
  local defs = require('apple.groups.todo_comments').get(palette.dark, config.defaults)
  t.eq(palette.dark.red, defs.TodoFgFIX.fg)
  t.eq(palette.dark.blue, defs.TodoFgTODO.fg)
  t.eq(palette.dark.orange, defs.TodoFgWARN.fg)
  t.eq(palette.dark.bg, defs.TodoBgTODO.fg)
  t.eq(palette.dark.blue, defs.TodoBgTODO.bg)
  t.eq('todo-comments', require('apple.groups.todo_comments').detect)
end)
```

- [ ] **Step 2: Run the tests to see them fail**

Run: `nvim --clean -l apple.nvim/tests/run.lua`
Expected: `... are listed` fails, and `module 'apple.groups.blink' not found`.

- [ ] **Step 3: Create the blink.cmp groups**

`apple.nvim/lua/apple/groups/blink.lua`:

```lua
-- blink.cmp: completion menu, documentation and signature help.
local M = {}

M.detect = 'blink.cmp'

---@param p table palette
---@param _ table options (unused here)
function M.get(p, _)
  return {
    BlinkCmpMenu = { fg = p.fg, bg = p.bg_alt },
    BlinkCmpMenuBorder = { fg = p.border, bg = p.bg_alt },
    BlinkCmpMenuSelection = { fg = p.selection_fg, bg = p.selection },
    BlinkCmpScrollBarThumb = { bg = p.border },
    BlinkCmpScrollBarGutter = { bg = p.bg_alt },
    BlinkCmpLabel = { fg = p.fg },
    BlinkCmpLabelDeprecated = { fg = p.comment, strikethrough = true },
    BlinkCmpLabelMatch = { fg = p.blue, bold = true },
    BlinkCmpLabelDetail = { fg = p.comment },
    BlinkCmpLabelDescription = { fg = p.comment },
    BlinkCmpSource = { fg = p.comment },
    BlinkCmpGhostText = { fg = p.comment },
    BlinkCmpDoc = { fg = p.fg, bg = p.bg_alt },
    BlinkCmpDocBorder = { fg = p.border, bg = p.bg_alt },
    BlinkCmpDocSeparator = { fg = p.border, bg = p.bg_alt },
    BlinkCmpDocCursorLine = { bg = p.border },
    BlinkCmpSignatureHelp = { fg = p.fg, bg = p.bg_alt },
    BlinkCmpSignatureHelpBorder = { fg = p.border, bg = p.bg_alt },
    BlinkCmpSignatureHelpActiveParameter = { bg = p.border, bold = true },

    -- Item kinds: same colors as the syntax groups they stand for
    BlinkCmpKind = { fg = p.teal },
    BlinkCmpKindText = { fg = p.fg },
    BlinkCmpKindMethod = { fg = p.blue },
    BlinkCmpKindFunction = { fg = p.blue },
    BlinkCmpKindConstructor = { fg = p.teal },
    BlinkCmpKindField = { fg = p.fg },
    BlinkCmpKindVariable = { fg = p.fg },
    BlinkCmpKindClass = { fg = p.teal },
    BlinkCmpKindInterface = { fg = p.teal },
    BlinkCmpKindModule = { fg = p.orange },
    BlinkCmpKindProperty = { fg = p.fg },
    BlinkCmpKindUnit = { fg = p.yellow },
    BlinkCmpKindValue = { fg = p.yellow },
    BlinkCmpKindEnum = { fg = p.teal },
    BlinkCmpKindKeyword = { fg = p.pink },
    BlinkCmpKindSnippet = { fg = p.purple },
    BlinkCmpKindColor = { fg = p.pink },
    BlinkCmpKindFile = { fg = p.blue },
    BlinkCmpKindReference = { fg = p.purple },
    BlinkCmpKindFolder = { fg = p.blue },
    BlinkCmpKindEnumMember = { fg = p.yellow },
    BlinkCmpKindConstant = { fg = p.yellow },
    BlinkCmpKindStruct = { fg = p.teal },
    BlinkCmpKindEvent = { fg = p.purple },
    BlinkCmpKindOperator = { fg = p.fg },
    BlinkCmpKindTypeParameter = { fg = p.teal },
  }
end

return M
```

- [ ] **Step 4: Create the gitsigns groups**

`apple.nvim/lua/apple/groups/gitsigns.lua`:

```lua
-- gitsigns.nvim: signs, line highlights, inline word diff, blame.
local util = require 'apple.util'

local M = {}

M.detect = 'gitsigns'

---@param p table palette
---@param _ table options (unused here)
function M.get(p, _)
  -- Staged signs are a dimmed version of the normal signs.
  local staged_add = util.mix(p.green, p.bg, 0.6)
  local staged_change = util.mix(p.blue, p.bg, 0.6)
  local staged_delete = util.mix(p.red, p.bg, 0.6)
  -- Inline word diff is a stronger version of the line background.
  local inline_add = util.mix(p.diff_add, p.bg, 0.35)
  local inline_change = util.mix(p.diff_change, p.bg, 0.35)
  local inline_delete = util.mix(p.diff_delete, p.bg, 0.35)

  return {
    GitSignsAdd = { fg = p.green },
    GitSignsChange = { fg = p.blue },
    GitSignsDelete = { fg = p.red },
    GitSignsTopdelete = { fg = p.red },
    GitSignsChangedelete = { fg = p.blue },
    GitSignsUntracked = { fg = p.orange },
    GitSignsAddNr = { fg = p.green },
    GitSignsChangeNr = { fg = p.blue },
    GitSignsDeleteNr = { fg = p.red },
    GitSignsAddLn = { bg = p.diff_add_bg },
    GitSignsChangeLn = { bg = p.diff_change_bg },
    GitSignsDeleteVirtLn = { bg = p.diff_delete_bg },
    GitSignsAddInline = { bg = inline_add },
    GitSignsChangeInline = { bg = inline_change },
    GitSignsDeleteInline = { bg = inline_delete },
    GitSignsAddPreview = { bg = p.diff_add_bg },
    GitSignsDeletePreview = { bg = p.diff_delete_bg },
    GitSignsStagedAdd = { fg = staged_add },
    GitSignsStagedChange = { fg = staged_change },
    GitSignsStagedDelete = { fg = staged_delete },
    GitSignsStagedTopdelete = { fg = staged_delete },
    GitSignsStagedChangedelete = { fg = staged_change },
    GitSignsCurrentLineBlame = { fg = p.comment },
  }
end

return M
```

- [ ] **Step 5: Create the which-key groups**

`apple.nvim/lua/apple/groups/which_key.lua`:

```lua
-- which-key.nvim: key hint popup.
local M = {}

M.detect = 'which-key'

---@param p table palette
---@param _ table options (unused here)
function M.get(p, _)
  return {
    WhichKey = { fg = p.blue, bold = true },
    WhichKeyGroup = { fg = p.teal },
    WhichKeyDesc = { fg = p.fg },
    WhichKeySeparator = { fg = p.comment },
    WhichKeyValue = { fg = p.comment },
    WhichKeyIcon = { fg = p.blue },
    WhichKeyNormal = { fg = p.fg, bg = p.bg_alt },
    WhichKeyBorder = { fg = p.border, bg = p.bg_alt },
    WhichKeyTitle = { fg = p.fg, bg = p.bg_alt, bold = true },
  }
end

return M
```

- [ ] **Step 6: Create the todo-comments groups**

`apple.nvim/lua/apple/groups/todo_comments.lua`:

```lua
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
```

- [ ] **Step 7: Register the integrations**

In `apple.nvim/lua/apple/groups/init.lua`:

```lua
M.integrations = { 'telescope', 'blink', 'gitsigns', 'which_key', 'todo_comments' }
```

- [ ] **Step 8: Run the tests to see them pass**

Run: `nvim --clean -l apple.nvim/tests/run.lua`
Expected: all pass, exit 0.

- [ ] **Step 9: Format and commit**

```bash
stylua apple.nvim
git add apple.nvim
git commit -m "Add blink, gitsigns, which-key and todo-comments groups

Written by Claude"
```

---

### Task 9: Integrations: mini.nvim, fidget, mason

**Files:**
- Create: `apple.nvim/lua/apple/groups/mini.lua`
- Create: `apple.nvim/lua/apple/groups/fidget.lua`
- Create: `apple.nvim/lua/apple/groups/mason.lua`
- Modify: `apple.nvim/lua/apple/groups/init.lua` (`M.integrations`)
- Modify: `apple.nvim/tests/integrations_spec.lua` (append)

**Interfaces:**
- Consumes: integration module contract from Task 7.
- Produces: `M.integrations = { ..., 'mini', 'fidget', 'mason' }`.

- [ ] **Step 1: Append failing tests**

Add to the end of `apple.nvim/tests/integrations_spec.lua`:

```lua
t.test('mini, fidget, mason are listed', function()
  for _, name in ipairs { 'mini', 'fidget', 'mason' } do
    t.ok(vim.tbl_contains(groups.integrations, name), name)
  end
end)

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

t.test('mini: icon colors map to the palette', function()
  local defs = require('apple.groups.mini').get(palette.dark, config.defaults)
  t.eq(palette.dark.blue, defs.MiniIconsBlue.fg)
  t.eq(palette.dark.teal, defs.MiniIconsCyan.fg)
  t.eq(palette.dark.comment, defs.MiniIconsGrey.fg)
  t.eq('mini', require('apple.groups.mini').detect)
end)

t.test('fidget: title is blue, tasks are gray', function()
  local defs = require('apple.groups.fidget').get(palette.dark, config.defaults)
  t.eq(palette.dark.blue, defs.FidgetTitle.fg)
  t.eq(palette.dark.comment, defs.FidgetTask.fg)
end)

t.test('mason: header is a blue block with readable text', function()
  local defs = require('apple.groups.mason').get(palette.light, config.defaults)
  t.eq(palette.light.blue, defs.MasonHeader.bg)
  t.min_contrast(defs.MasonHeader.fg, defs.MasonHeader.bg, 3.0, 'MasonHeader')
  t.eq(palette.light.comment, defs.MasonMuted.fg)
end)
```

- [ ] **Step 2: Run the tests to see them fail**

Run: `nvim --clean -l apple.nvim/tests/run.lua`
Expected: `mini, fidget, mason are listed` fails; `module 'apple.groups.mini' not found`.

- [ ] **Step 3: Create the mini groups**

`apple.nvim/lua/apple/groups/mini.lua`:

```lua
-- mini.nvim modules used in this config: statusline, icons, surround, ai.
local M = {}

-- Any lua/mini/*.lua file on the runtimepath counts.
M.detect = 'mini'

---@param p table palette
---@param _ table options (unused here)
function M.get(p, _)
  return {
    -- mini.statusline: a colored block per mode, grays for the other sections
    MiniStatuslineModeNormal = { fg = p.bg, bg = p.blue, bold = true },
    MiniStatuslineModeInsert = { fg = p.bg, bg = p.green, bold = true },
    MiniStatuslineModeVisual = { fg = p.bg, bg = p.purple, bold = true },
    MiniStatuslineModeReplace = { fg = p.bg, bg = p.red, bold = true },
    MiniStatuslineModeCommand = { fg = p.bg, bg = p.orange, bold = true },
    MiniStatuslineModeOther = { fg = p.bg, bg = p.teal, bold = true },
    MiniStatuslineDevinfo = { fg = p.fg, bg = p.border },
    MiniStatuslineFilename = { fg = p.fg, bg = p.bg_alt },
    MiniStatuslineFileinfo = { fg = p.fg, bg = p.border },
    MiniStatuslineInactive = { fg = p.comment, bg = p.bg_alt },

    -- mini.icons
    MiniIconsAzure = { fg = p.blue },
    MiniIconsBlue = { fg = p.blue },
    MiniIconsCyan = { fg = p.teal },
    MiniIconsGreen = { fg = p.green },
    MiniIconsGrey = { fg = p.comment },
    MiniIconsOrange = { fg = p.orange },
    MiniIconsPurple = { fg = p.purple },
    MiniIconsRed = { fg = p.red },
    MiniIconsYellow = { fg = p.yellow },

    -- mini.surround
    MiniSurround = { fg = p.search_fg, bg = p.cur_search },

    -- mini.pick / mini.notify / mini.indentscope (cheap to add, used by many configs)
    MiniPickBorder = { fg = p.border, bg = p.bg_alt },
    MiniPickBorderBusy = { fg = p.orange, bg = p.bg_alt },
    MiniPickBorderText = { fg = p.fg, bg = p.bg_alt, bold = true },
    MiniPickHeader = { fg = p.blue, bg = p.bg_alt },
    MiniPickMatchCurrent = { fg = p.selection_fg, bg = p.selection },
    MiniPickMatchMarked = { fg = p.purple, bg = p.bg_alt },
    MiniPickMatchRanges = { fg = p.blue, bold = true },
    MiniPickNormal = { fg = p.fg, bg = p.bg_alt },
    MiniPickPreviewLine = { bg = p.border },
    MiniPickPrompt = { fg = p.blue, bg = p.bg_alt },
    MiniNotifyBorder = { fg = p.border, bg = p.bg_alt },
    MiniNotifyNormal = { fg = p.fg, bg = p.bg_alt },
    MiniNotifyTitle = { fg = p.blue, bg = p.bg_alt, bold = true },
    MiniIndentscopeSymbol = { fg = p.line_nr },
  }
end

return M
```

- [ ] **Step 4: Create the fidget groups**

`apple.nvim/lua/apple/groups/fidget.lua`:

```lua
-- fidget.nvim: LSP progress messages in the corner.
local M = {}

M.detect = 'fidget'

---@param p table palette
---@param _ table options (unused here)
function M.get(p, _)
  return {
    FidgetTitle = { fg = p.blue, bold = true },
    FidgetTask = { fg = p.comment },
    FidgetNormal = { fg = p.comment, bg = p.none },
  }
end

return M
```

- [ ] **Step 5: Create the mason groups**

`apple.nvim/lua/apple/groups/mason.lua`:

```lua
-- mason.nvim: the :Mason package window.
local M = {}

M.detect = 'mason'

---@param p table palette
---@param _ table options (unused here)
function M.get(p, _)
  return {
    MasonNormal = { fg = p.fg, bg = p.bg_alt },
    MasonHeader = { fg = p.bg, bg = p.blue, bold = true },
    MasonHeaderSecondary = { fg = p.bg, bg = p.orange, bold = true },
    MasonHeading = { fg = p.fg, bold = true },
    MasonHighlight = { fg = p.blue },
    MasonHighlightBlock = { fg = p.bg, bg = p.blue },
    MasonHighlightBlockBold = { fg = p.bg, bg = p.blue, bold = true },
    MasonHighlightSecondary = { fg = p.orange },
    MasonHighlightBlockSecondary = { fg = p.bg, bg = p.orange },
    MasonHighlightBlockBoldSecondary = { fg = p.bg, bg = p.orange, bold = true },
    MasonLink = { fg = p.blue, underline = true },
    MasonMuted = { fg = p.comment },
    MasonMutedBlock = { fg = p.fg, bg = p.border },
    MasonMutedBlockBold = { fg = p.fg, bg = p.border, bold = true },
    MasonError = { fg = p.red },
    MasonWarning = { fg = p.orange },
  }
end

return M
```

- [ ] **Step 6: Register the integrations**

In `apple.nvim/lua/apple/groups/init.lua`:

```lua
M.integrations = { 'telescope', 'blink', 'gitsigns', 'which_key', 'todo_comments', 'mini', 'fidget', 'mason' }
```

- [ ] **Step 7: Run the tests to see them pass**

Run: `nvim --clean -l apple.nvim/tests/run.lua`
Expected: all pass, exit 0.

- [ ] **Step 8: Format and commit**

```bash
stylua apple.nvim
git add apple.nvim
git commit -m "Add mini, fidget and mason groups

Written by Claude"
```

---

### Task 10: Integrations: indent-blankline, neo-tree, nvim-dap

**Files:**
- Create: `apple.nvim/lua/apple/groups/indent_blankline.lua`
- Create: `apple.nvim/lua/apple/groups/neo_tree.lua`
- Create: `apple.nvim/lua/apple/groups/dap.lua`
- Modify: `apple.nvim/lua/apple/groups/init.lua` (`M.integrations`)
- Modify: `apple.nvim/tests/integrations_spec.lua` (append)

**Interfaces:**
- Consumes: integration module contract from Task 7.
- Produces: final `M.integrations` list with all 11 names from the spec.

- [ ] **Step 1: Append failing tests**

Add to the end of `apple.nvim/tests/integrations_spec.lua`:

```lua
t.test('the integration list matches the spec', function()
  t.eq({ 'telescope', 'blink', 'gitsigns', 'which_key', 'todo_comments', 'mini', 'fidget', 'mason', 'indent_blankline', 'neo_tree', 'dap' }, groups.integrations)
end)

t.test('indent_blankline: guides use the border gray, scope is stronger', function()
  local defs = require('apple.groups.indent_blankline').get(palette.dark, config.defaults)
  t.eq(palette.dark.border, defs.IblIndent.fg)
  t.eq(palette.dark.comment, defs.IblScope.fg)
  t.eq('ibl', require('apple.groups.indent_blankline').detect)
end)

t.test('neo_tree: window uses bg_alt, folders are blue, git states colored', function()
  local defs = require('apple.groups.neo_tree').get(palette.light, config.defaults)
  t.eq(palette.light.bg_alt, defs.NeoTreeNormal.bg)
  t.eq(palette.light.blue, defs.NeoTreeDirectoryName.fg)
  t.eq(palette.light.green, defs.NeoTreeGitAdded.fg)
  t.eq(palette.light.red, defs.NeoTreeGitDeleted.fg)
  t.eq('neo-tree', require('apple.groups.neo_tree').detect)
end)

t.test('dap: breakpoint red, stopped green, dapui detected too', function()
  local defs = require('apple.groups.dap').get(palette.dark, config.defaults)
  t.eq(palette.dark.red, defs.DapBreakpoint.fg)
  t.eq(palette.dark.green, defs.DapStopped.fg)
  t.eq(palette.dark.diff_add_bg, defs.DapStoppedLine.bg)
  t.eq({ 'dap', 'dapui' }, require('apple.groups.dap').detect)
end)
```

- [ ] **Step 2: Run the tests to see them fail**

Run: `nvim --clean -l apple.nvim/tests/run.lua`
Expected: `the integration list matches the spec` fails; `module 'apple.groups.indent_blankline' not found`.

- [ ] **Step 3: Create the indent-blankline groups**

`apple.nvim/lua/apple/groups/indent_blankline.lua`:

```lua
-- indent-blankline.nvim (module `ibl`): indent guides.
local M = {}

M.detect = 'ibl'

---@param p table palette
---@param _ table options (unused here)
function M.get(p, _)
  return {
    IblIndent = { fg = p.border },
    IblWhitespace = { fg = p.border },
    IblScope = { fg = p.comment },
    -- Old names, still used by some configs
    IndentBlanklineChar = { fg = p.border },
    IndentBlanklineContextChar = { fg = p.comment },
  }
end

return M
```

- [ ] **Step 4: Create the neo-tree groups**

`apple.nvim/lua/apple/groups/neo_tree.lua`:

```lua
-- neo-tree.nvim: file explorer side window.
local M = {}

M.detect = 'neo-tree'

---@param p table palette
---@param _ table options (unused here)
function M.get(p, _)
  return {
    NeoTreeNormal = { fg = p.fg, bg = p.bg_alt },
    NeoTreeNormalNC = { fg = p.fg, bg = p.bg_alt },
    NeoTreeEndOfBuffer = { fg = p.bg_alt, bg = p.bg_alt },
    NeoTreeWinSeparator = { fg = p.border, bg = p.bg_alt },
    NeoTreeCursorLine = { bg = p.border },
    NeoTreeStatusLine = { fg = p.fg, bg = p.bg_alt },
    NeoTreeStatusLineNC = { fg = p.comment, bg = p.bg_alt },
    NeoTreeSignColumn = { bg = p.bg_alt },
    NeoTreeVertSplit = { fg = p.border, bg = p.bg_alt },

    NeoTreeRootName = { fg = p.blue, bold = true },
    NeoTreeDirectoryName = { fg = p.blue },
    NeoTreeDirectoryIcon = { fg = p.blue },
    NeoTreeFileName = { fg = p.fg },
    NeoTreeFileNameOpened = { fg = p.fg, bold = true },
    NeoTreeFileIcon = { fg = p.fg },
    NeoTreeSymbolicLinkTarget = { fg = p.teal },
    NeoTreeIndentMarker = { fg = p.border },
    NeoTreeExpander = { fg = p.line_nr },
    NeoTreeDotfile = { fg = p.comment },
    NeoTreeHiddenByName = { fg = p.comment },
    NeoTreeMessage = { fg = p.comment, italic = true },
    NeoTreeModified = { fg = p.orange },
    NeoTreeDimText = { fg = p.comment },

    NeoTreeGitAdded = { fg = p.green },
    NeoTreeGitModified = { fg = p.blue },
    NeoTreeGitDeleted = { fg = p.red },
    NeoTreeGitRenamed = { fg = p.purple },
    NeoTreeGitUntracked = { fg = p.orange },
    NeoTreeGitIgnored = { fg = p.comment },
    NeoTreeGitConflict = { fg = p.red, bold = true },
    NeoTreeGitStaged = { fg = p.green },
    NeoTreeGitUnstaged = { fg = p.orange },

    NeoTreeTitleBar = { fg = p.bg, bg = p.blue, bold = true },
    NeoTreeFloatBorder = { fg = p.border, bg = p.bg_alt },
    NeoTreeFloatTitle = { fg = p.fg, bg = p.bg_alt, bold = true },
    NeoTreeFloatNormal = { fg = p.fg, bg = p.bg_alt },
    NeoTreeTabActive = { fg = p.fg, bg = p.bg_alt, bold = true },
    NeoTreeTabInactive = { fg = p.comment, bg = p.bg },
    NeoTreeTabSeparatorActive = { fg = p.bg_alt, bg = p.bg_alt },
    NeoTreeTabSeparatorInactive = { fg = p.bg, bg = p.bg },
  }
end

return M
```

- [ ] **Step 5: Create the dap groups**

`apple.nvim/lua/apple/groups/dap.lua`:

```lua
-- nvim-dap and nvim-dap-ui: breakpoints, stopped line, debug panels.
local M = {}

M.detect = { 'dap', 'dapui' }

---@param p table palette
---@param _ table options (unused here)
function M.get(p, _)
  return {
    -- nvim-dap signs
    DapBreakpoint = { fg = p.red },
    DapBreakpointCondition = { fg = p.orange },
    DapBreakpointRejected = { fg = p.comment },
    DapLogPoint = { fg = p.blue },
    DapStopped = { fg = p.green },
    DapStoppedLine = { bg = p.diff_add_bg },

    -- nvim-dap-ui panels
    DapUIScope = { fg = p.blue },
    DapUIType = { fg = p.teal },
    DapUIValue = { fg = p.fg },
    DapUIModifiedValue = { fg = p.blue, bold = true },
    DapUIDecoration = { fg = p.blue },
    DapUIThread = { fg = p.green },
    DapUIStoppedThread = { fg = p.blue },
    DapUIFrameName = { fg = p.fg },
    DapUISource = { fg = p.purple },
    DapUILineNumber = { fg = p.blue },
    DapUIFloatBorder = { fg = p.border },
    DapUIWatchesEmpty = { fg = p.red },
    DapUIWatchesValue = { fg = p.green },
    DapUIWatchesError = { fg = p.red },
    DapUIBreakpointsPath = { fg = p.blue },
    DapUIBreakpointsInfo = { fg = p.green },
    DapUIBreakpointsCurrentLine = { fg = p.green, bold = true },
    DapUIBreakpointsLine = { fg = p.blue },
    DapUIBreakpointsDisabledLine = { fg = p.comment },
    DapUICurrentFrameName = { fg = p.green, bold = true },
    DapUIStepOver = { fg = p.blue },
    DapUIStepInto = { fg = p.blue },
    DapUIStepBack = { fg = p.blue },
    DapUIStepOut = { fg = p.blue },
    DapUIStop = { fg = p.red },
    DapUIPlayPause = { fg = p.green },
    DapUIRestart = { fg = p.green },
    DapUIUnavailable = { fg = p.comment },
    DapUIWinSelect = { fg = p.blue, bold = true },
    DapUIEndofBuffer = { fg = p.bg },
  }
end

return M
```

- [ ] **Step 6: Register the integrations**

In `apple.nvim/lua/apple/groups/init.lua`:

```lua
M.integrations = { 'telescope', 'blink', 'gitsigns', 'which_key', 'todo_comments', 'mini', 'fidget', 'mason', 'indent_blankline', 'neo_tree', 'dap' }
```

- [ ] **Step 7: Run the tests to see them pass**

Run: `nvim --clean -l apple.nvim/tests/run.lua`
Expected: all pass, exit 0.

- [ ] **Step 8: Format and commit**

```bash
stylua apple.nvim
git add apple.nvim
git commit -m "Add indent-blankline, neo-tree and dap groups

Written by Claude"
```

---

### Task 11: Switch init.lua from Catppuccin to apple

**Files:**
- Modify: `init.lua:420-445` (the `[[ Colorscheme ]]` block)
- Modify: `nvim-pack-lock.json` (remove the `"nvim"` entry)

**Interfaces:**
- Consumes: `require('apple').setup`, `:colorscheme apple`.

- [ ] **Step 1: Replace the colorscheme block**

In `init.lua`, replace everything from the line `-- [[ Colorscheme ]]` to the line `-- or Neovim stops following the terminal.` (the block that ends just before `-- Highlight todo, notes, etc in comments`) with:

```lua
  -- [[ Colorscheme ]]
  -- The "apple" colorscheme is a plugin folder inside this config: apple.nvim/.
  -- It uses Apple system colors. Add the folder to the runtimepath so
  -- `:colorscheme apple` and `require('apple')` work. When the theme moves to
  -- its own repository, replace the next line with `vim.pack.add { gh '<user>/apple.nvim' }`.
  vim.opt.runtimepath:prepend(vim.fn.stdpath 'config' .. '/apple.nvim')
  require('apple').setup {
    -- 'auto' follows 'background': dark terminal -> dark flavor, light -> light.
    flavor = 'auto',
    styles = {
      comments = {}, -- no italics in comments
    },
    -- Integrations (telescope, blink, gitsigns, mini, ...) are detected automatically.
  }

  -- Load the colorscheme here.
  -- Neovim reads the terminal background at startup, so the right flavor is picked.
  vim.cmd.colorscheme 'apple'

  -- [[ Follow macOS appearance ]]
  -- No timer is needed. Ghostty follows the macOS appearance and tells Neovim
  -- when its theme changes (DEC mode 2031). Neovim 0.11+ then updates
  -- 'background' and reloads the colorscheme. Never set 'background' here,
  -- or Neovim stops following the terminal.
```

Check with `grep -n catppuccin init.lua`: expected no output.

- [ ] **Step 2: Remove Catppuccin from the lock file**

In `nvim-pack-lock.json`, delete this object (and the comma that keeps the JSON valid):

```json
    "nvim": {
      "rev": "edefef779ab08ce1a4a404713e3012b0d202bd35",
      "src": "https://github.com/catppuccin/nvim"
    },
```

Check: `python3 -m json.tool nvim-pack-lock.json > /dev/null && echo ok` prints `ok`.

- [ ] **Step 3: Start Neovim with the real config**

Run: `nvim --headless -c 'lua print(vim.g.colors_name, vim.o.background)' -c 'lua print(vim.inspect(vim.api.nvim_get_hl(0, {name="TelescopeNormal"})))' -c qa`
Expected: prints `apple dark` (or `apple light`), and a non-empty table for `TelescopeNormal` (telescope was auto-detected). No error messages.

Then open Neovim normally, look at a Lua file, run `:Telescope find_files`, open the completion menu, and check `:checkhealth` has no new errors. Toggle macOS appearance (or `:set background=light`) and confirm the switch.

- [ ] **Step 4: Remove the old plugin from disk (optional, local only)**

Run: `nvim --headless -c 'lua vim.pack.del { "nvim" }' -c qa`
Expected: no error. This only cleans `~/.local/share/nvim/site/pack/core/opt/nvim`; skip if it errors.

- [ ] **Step 5: Run the tests and stylua once more**

Run: `nvim --clean -l apple.nvim/tests/run.lua && stylua --check .`
Expected: all tests pass, stylua prints nothing.

- [ ] **Step 6: Commit**

```bash
git add init.lua nvim-pack-lock.json
git commit -m "Switch colorscheme from catppuccin to apple.nvim

Written by Claude"
```

---

### Task 12: README, LICENSE and CI

**Files:**
- Create: `apple.nvim/README.md`
- Create: `apple.nvim/LICENSE`
- Create: `.github/workflows/apple-tests.yml`

**Interfaces:**
- Consumes: the finished plugin.
- Produces: docs and CI. No code interfaces.

- [ ] **Step 1: Write the README**

`apple.nvim/README.md`:

````markdown
# apple.nvim

A Neovim colorscheme built from Apple system colors
([Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/color)).
Two flavors, dark and light. The flavor follows `'background'`, so it switches
with your terminal and macOS appearance.

Syntax colors follow Xcode: pink keywords, red strings, yellow numbers, blue
functions, teal types, orange preprocessor.

## Requirements

- Neovim 0.11 or newer.
- A terminal that reports its theme (Ghostty, WezTerm, kitty, iTerm2, ...) if
  you want automatic switching.

## Install

With `vim.pack` (Neovim 0.12+):

```lua
vim.pack.add { 'https://github.com/<user>/apple.nvim' }
vim.cmd.colorscheme 'apple'
```

With lazy.nvim:

```lua
{ '<user>/apple.nvim', priority = 1000, config = function() vim.cmd.colorscheme 'apple' end }
```

Inside a config folder (no plugin manager):

```lua
vim.opt.runtimepath:prepend(vim.fn.stdpath 'config' .. '/apple.nvim')
vim.cmd.colorscheme 'apple'
```

## Options

`setup()` is optional. These are the defaults:

```lua
require('apple').setup {
  flavor = 'auto',            -- 'auto' | 'dark' | 'light'
  styles = {
    comments = {},            -- e.g. { italic = true }
    keywords = { bold = true },
    functions = {},
    strings = {},
  },
  integrations = {},          -- e.g. { telescope = false, neo_tree = true }
  on_highlights = nil,        -- function(groups, palette)
}
vim.cmd.colorscheme 'apple'
```

- `flavor = 'auto'` uses `'background'`. Never set `'background'` yourself in
  that mode, or Neovim stops following the terminal.
- A style table **replaces** the default for that key. `keywords = {}` turns
  bold off.
- `on_highlights` gets the full group table before it is applied:

```lua
on_highlights = function(groups, p)
  groups.Comment = { fg = p.blue }
  groups.MyGroup = { fg = p.green, bold = true }
end
```

## Integrations

Integrations are detected automatically when the plugin is on the runtimepath.
Force one on or off with `integrations = { name = true | false }`.

| name               | plugin                        |
|--------------------|-------------------------------|
| `telescope`        | telescope.nvim                |
| `blink`            | blink.cmp                     |
| `gitsigns`         | gitsigns.nvim                 |
| `which_key`        | which-key.nvim                |
| `todo_comments`    | todo-comments.nvim            |
| `mini`             | mini.nvim (statusline, icons, surround, pick, notify) |
| `fidget`           | fidget.nvim                   |
| `mason`            | mason.nvim                    |
| `indent_blankline` | indent-blankline.nvim         |
| `neo_tree`         | neo-tree.nvim                 |
| `dap`              | nvim-dap, nvim-dap-ui         |

Treesitter and the built-in LSP client are always styled.

## Palette

| name       | dark      | light     |
|------------|-----------|-----------|
| bg         | `#1C1C1E` | `#F2F2F7` |
| bg_alt     | `#2C2C2E` | `#E5E5EA` |
| border     | `#48484A` | `#C7C7CC` |
| line_nr    | `#636366` | `#AEAEB2` |
| comment    | `#8E8E93` | `#6C6C70` |
| fg         | `#F2F2F7` | `#1C1C1E` |
| red        | `#FF6165` | `#E9152D` |
| orange     | `#FFA056` | `#C55300` |
| yellow     | `#FEDF43` | `#A16A00` |
| green      | `#4AD968` | `#008932` |
| teal       | `#3BDDEC` | `#008198` |
| blue       | `#5CB8FF` | `#1E6EF4` |
| purple     | `#EA8DFF` | `#B02FC2` |
| pink       | `#FF8AC4` | `#E7124D` |

## Development

Run the tests (no dependencies):

```
nvim --clean -l tests/run.lua
```

Add an integration: create `lua/apple/groups/<name>.lua` that returns
`{ detect = '<module>', get = function(p, opts) return { ... } end }`, and add
`<name>` to `M.integrations` in `lua/apple/groups/init.lua`. The generic test
in `tests/integrations_spec.lua` checks it automatically.

## License

MIT
````

Replace `<user>` with the GitHub user name (`sergiivelykodnyi`).

- [ ] **Step 2: Add the license**

Copy the MIT text from the repo root:

```bash
cp LICENSE.md apple.nvim/LICENSE
```

Open `apple.nvim/LICENSE` and make sure the copyright line names the author (edit the year/name line if it still says kickstart's author: `Copyright (c) 2026 Sergii Velykodnyi`).

- [ ] **Step 3: Add the CI workflow**

`.github/workflows/apple-tests.yml`:

```yaml
# Run the apple.nvim colorscheme tests on the stable Neovim release.
name: apple.nvim tests
on:
  push:
    branches:
      - main
  pull_request:

jobs:
  test:
    name: Tests
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Code
        uses: actions/checkout@v7
      - name: Install Neovim
        uses: rhysd/action-setup-vim@v1
        with:
          neovim: true
          version: stable
      - name: Run tests
        run: nvim --clean -l apple.nvim/tests/run.lua
```

- [ ] **Step 4: Check the workflow file and the tests**

Run: `nvim --clean -l apple.nvim/tests/run.lua && python3 -c "import yaml,sys; yaml.safe_load(open('.github/workflows/apple-tests.yml')); print('yaml ok')"`
Expected: tests pass and `yaml ok`. If `yaml` is not installed, skip the second part; the file is small enough to check by eye.

- [ ] **Step 5: Commit**

```bash
git add apple.nvim/README.md apple.nvim/LICENSE .github/workflows/apple-tests.yml
git commit -m "Add apple.nvim README, license and CI workflow

Written by Claude"
```

- [ ] **Step 6: Final check of the whole branch**

Run:

```bash
nvim --clean -l apple.nvim/tests/run.lua
stylua --check .
nvim --headless -c 'lua print(vim.g.colors_name)' -c qa
git status --short
```

Expected: all tests pass, stylua clean, prints `apple`, working tree clean.
