# One Dark Pro Night Flat Colorscheme Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace apple.nvim with a standalone Neovim colorscheme that looks exactly like VSCode with the "One Dark Pro Night Flat" theme.

**Architecture:** A plain Lua module in `lua/custom/plugins/colorscheme/`. `palette.lua` holds every color with its VSCode key. Group files each export `get(p)` and return a table of highlight definitions; integration files also export `detect`. `init.lua` clears highlights, applies the core groups, applies every detected integration, sets the terminal colors, and re-checks integrations once at `VimEnter`. A headless test runner in `tests/` runs in CI.

**Tech Stack:** Neovim 0.12.5, Lua, `nvim --clean -l` for tests, GitHub Actions, stylua.

**Spec:** `docs/superpowers/specs/2026-10-09-onedark-colorscheme-design.md`

## Global Constraints

- Work on branch `onedark-colorscheme`. Do not commit to `main`.
- `~/.config/nvim` is a symlink to this repo, so a normal `nvim` loads the code of the current branch.
- No bold, no italic in any highlight group. Only `undercurl` (diagnostics, spelling) and `underline` (links, `Underlined`).
- Every color is `#rrggbb`, lowercase, six hex digits, or the string `'NONE'`.
- Dark only. The module never sets `'background'`.
- No `setup()` and no options. `require 'custom.plugins.colorscheme'` applies the theme.
- `vim.g.colors_name` is `'onedark'`.
- Group files reference colors only through the palette table `p`. No hex literal outside `palette.lua`.
- Lua style: 2 spaces, single quotes, no call parentheses for one string or table argument, column width 160 (`.stylua.toml`). CI runs `stylua --check .`. Stylua binary: `~/.local/share/nvim/mason/bin/stylua`.
- Comments are short and in simple English. Code comments are written for a professional developer.
- Every commit message ends with exactly one trailer line: `Written-by: Claude`. No email address, no `Co-authored-by`, no session link. Do not change Git signing settings and do not use `--no-gpg-sign`. A subagent that commits must get this rule in its prompt.
- Run all commands from the repo root: `/Users/sergii/github/personal/neovim-config`.
- Test command: `nvim --clean -l lua/custom/plugins/colorscheme/tests/run.lua`. Exit code 0 means pass.

## Review Focus

Inputs the spec implies but does not spell out. Each one has a test in the task named.

1. A group file references a palette key that does not exist (`p.purpel`). Neovim would silently show the default color. The strict palette test in Task 3 must fail. (Task 3)
2. A plugin is added to the runtimepath after the theme ran (kickstart does this for every plugin after the colorscheme line). Its groups must appear after `VimEnter` without a second `require`. (Task 4)
3. One integration file throws. The theme must still apply the core groups and the other integrations, and report the error once. (Task 4)
4. `require 'custom.plugins.colorscheme'` runs twice (for example after `:source init.lua`). The theme must apply again without an error and without duplicate autocmds. (Task 4)
5. A buffer with no tree-sitter parser (an unknown file type). The classic Vim groups must be set so the file is not plain white. (Task 3)

## File Structure

| File | Role |
|---|---|
| `lua/custom/plugins/colorscheme/init.lua` | `load()`: clear, core groups, integrations, terminal colors, VimEnter re-check. Runs `load()` when required |
| `lua/custom/plugins/colorscheme/palette.lua` | Every color with its VSCode key, plus `terminal` list |
| `lua/custom/plugins/colorscheme/util.lua` | `has_plugin(names)`, `apply(groups)` |
| `lua/custom/plugins/colorscheme/groups/editor.lua` | Built-in UI groups |
| `lua/custom/plugins/colorscheme/groups/syntax.lua` | Classic Vim syntax groups |
| `lua/custom/plugins/colorscheme/groups/treesitter.lua` | `@` captures |
| `lua/custom/plugins/colorscheme/groups/lsp.lua` | `@lsp.*` and `Diagnostic*` |
| `lua/custom/plugins/colorscheme/groups/<plugin>.lua` | One file per integration: `detect` and `get(p)` |
| `lua/custom/plugins/colorscheme/tests/run.lua` | Test runner |
| `lua/custom/plugins/colorscheme/tests/helpers.lua` | `test`, `eq`, `ok`, `strict`, `report` |
| `lua/custom/plugins/colorscheme/tests/*_spec.lua` | Tests |
| `.github/workflows/colorscheme-tests.yml` | CI for the tests |
| `init.lua` | Replace the apple block with one `require` |

---

### Task 1: Move apple.nvim out of this repo

**Files:**
- Move: `apple.nvim/` to `../apple.nvim/`
- Move: `.github/workflows/apple-tests.yml` to `../apple.nvim/.github/workflows/tests.yml`
- Move: `docs/superpowers/specs/2026-09-30-apple-colorscheme-design.md` to `../apple.nvim/docs/superpowers/specs/`
- Move: `docs/superpowers/plans/2026-09-30-apple-colorscheme.md` to `../apple.nvim/docs/superpowers/plans/`
- Modify: `init.lua:420-437` (the `[[ Colorscheme ]]` block)

- [ ] **Step 1: Check that the target does not exist**

Run: `ls -d ../apple.nvim`
Expected: `No such file or directory`. If it exists, stop and ask the user.

- [ ] **Step 2: Move the folder and the related files**

```bash
git mv apple.nvim ../apple.nvim 2>/dev/null || mv apple.nvim ../apple.nvim
mkdir -p ../apple.nvim/.github/workflows ../apple.nvim/docs/superpowers/specs ../apple.nvim/docs/superpowers/plans
mv .github/workflows/apple-tests.yml ../apple.nvim/.github/workflows/tests.yml
mv docs/superpowers/specs/2026-09-30-apple-colorscheme-design.md ../apple.nvim/docs/superpowers/specs/
mv docs/superpowers/plans/2026-09-30-apple-colorscheme.md ../apple.nvim/docs/superpowers/plans/
```

`git mv` to a path outside the repo fails, so the fallback `mv` is expected. Git sees the result as deletions.

- [ ] **Step 3: Fix the test path in the moved workflow**

In `../apple.nvim/.github/workflows/tests.yml`, change the last line from
`run: nvim --clean -l apple.nvim/tests/run.lua` to `run: nvim --clean -l tests/run.lua`.
The apple test runner computes its root from its own path, so it works from the new location.

- [ ] **Step 4: Check that the moved tests still pass**

Run: `nvim --clean -l ../apple.nvim/tests/run.lua | tail -1`
Expected: `N passed, 0 failed`

- [ ] **Step 5: Replace the apple block in init.lua**

Replace these lines in `init.lua` (the whole `[[ Colorscheme ]]` block, from the comment to `vim.cmd.colorscheme 'apple'`):

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
```

with:

```lua
  -- [[ Colorscheme ]]
  -- One Dark Pro Night Flat, built from the VSCode theme. See lua/custom/plugins/colorscheme/.
  -- The module does not exist yet; the next commits add it.
```

- [ ] **Step 6: Check that Neovim starts without an error**

Run: `nvim --headless "+lua print(vim.g.colors_name)" +qa 2>&1 | tail -3`
Expected: `nil` and no error line. The default colorscheme is active.

- [ ] **Step 7: Check that nothing else references apple**

Run: `grep -rn -i "apple" --exclude-dir=.git . | grep -v "docs/superpowers/specs/2026-10-09" | grep -v "docs/superpowers/plans/2026-10-09"`
Expected: no output.

- [ ] **Step 8: Commit**

```bash
git add -A
git commit -m "Move apple.nvim to its own folder outside this repo

The theme gets its own repository. Its CI workflow, spec and plan go
with it. init.lua no longer loads it; the next commits add the One Dark
colorscheme in its place.

Written-by: Claude"
```

---

### Task 2: Palette, util, and the test runner

**Files:**
- Create: `lua/custom/plugins/colorscheme/palette.lua`
- Create: `lua/custom/plugins/colorscheme/util.lua`
- Create: `lua/custom/plugins/colorscheme/tests/run.lua`
- Create: `lua/custom/plugins/colorscheme/tests/helpers.lua`
- Create: `lua/custom/plugins/colorscheme/tests/palette_spec.lua`
- Create: `lua/custom/plugins/colorscheme/tests/util_spec.lua`

**Interfaces:**
- Produces: `require('custom.plugins.colorscheme.palette')` returns a table of `name = '#rrggbb'` plus `none = 'NONE'` and `terminal = { 16 strings }`.
- Produces: `util.has_plugin(names: string|string[]): boolean`, `util.apply(groups: table<string, vim.api.keyset.highlight>)`.
- Produces: test helpers `t.test(name, fn)`, `t.eq(expected, actual, msg)`, `t.ok(value, msg)`, `t.strict(tbl)`, `t.unload(prefix)`, `t.report()`.

- [ ] **Step 1: Write the test runner and helpers**

`lua/custom/plugins/colorscheme/tests/run.lua`:

```lua
-- Test runner for the colorscheme.
-- Run from anywhere: nvim --clean -l lua/custom/plugins/colorscheme/tests/run.lua
local script = debug.getinfo(1, 'S').source:sub(2)
local tests_dir = vim.fn.fnamemodify(script, ':p:h')
-- tests -> colorscheme -> plugins -> custom -> lua -> repo root
local root = vim.fn.fnamemodify(tests_dir, ':h:h:h:h:h')

vim.opt.runtimepath:prepend(root)
package.path = tests_dir .. '/?.lua;' .. package.path

local t = require 'helpers'
local specs = vim.fn.glob(tests_dir .. '/*_spec.lua', false, true)
table.sort(specs)
for _, file in ipairs(specs) do
  print('\n# ' .. vim.fn.fnamemodify(file, ':t'))
  dofile(file)
end
os.exit(t.report())
```

`lua/custom/plugins/colorscheme/tests/helpers.lua`:

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
  if not vim.deep_equal(expected, actual) then error(('%s: expected %s, got %s'):format(msg or 'eq', vim.inspect(expected), vim.inspect(actual)), 2) end
end

function M.ok(value, msg)
  if not value then error(msg or 'expected a true value', 2) end
end

-- A read-only view of a table that errors on unknown keys.
-- Used to catch typos like p.purpel in group files.
function M.strict(tbl)
  return setmetatable({}, {
    __index = function(_, key)
      local value = tbl[key]
      if value == nil then error(('unknown palette key: %s'):format(tostring(key)), 2) end
      return value
    end,
    __newindex = function(_, key) error(('palette is read-only: %s'):format(tostring(key)), 2) end,
  })
end

-- Convert a color number from nvim_get_hl() to '#rrggbb'.
function M.hex(n) return n and ('#%06x'):format(n) or nil end

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

- [ ] **Step 2: Write the failing palette test**

`lua/custom/plugins/colorscheme/tests/palette_spec.lua`:

```lua
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
  t.eq({
    '#3f4451', '#e05561', '#8cc265', '#d18f52', '#4aa5f0', '#c162de', '#42b3c2', '#d7dae0',
    '#4f5666', '#ff616e', '#a5e075', '#f0a45d', '#4dc4ff', '#de73ff', '#4cd1e0', '#e6e6e6',
  }, p.terminal, 'terminal')
end)
```

- [ ] **Step 3: Run the tests to verify they fail**

Run: `nvim --clean -l lua/custom/plugins/colorscheme/tests/run.lua`
Expected: an error `module 'custom.plugins.colorscheme.palette' not found`.

- [ ] **Step 4: Write the palette**

`lua/custom/plugins/colorscheme/palette.lua`:

```lua
-- One Dark Pro Night Flat colors.
-- Source: themes/OneDark-Pro-night-flat.json in https://github.com/Binaryify/OneDark-Pro.
-- Each value names its VSCode key. Values with transparency are blended onto
-- the editor background once; the original value is in the comment.
return {
  none = 'NONE',

  -- Syntax: the "classic" text colors of the theme
  fg = '#abb2bf', -- editor.foreground (lightWhite)
  red = '#e06c75', -- coral: variables, properties, tags
  orange = '#d19a66', -- whiskey: numbers, constants, attributes
  yellow = '#e5c07b', -- chalky: types, classes, namespaces
  green = '#98c379', -- green: strings
  cyan = '#56b6c2', -- fountainBlue: operators, escapes, enum members
  blue = '#61afef', -- malibu: functions, links
  purple = '#c678dd', -- purple: keywords
  comment = '#7f848e', -- lightDark: comments
  dim = '#5c6370', -- dark: markdown quotes
  error = '#f44747', -- error: invalid tokens

  -- UI: workbench colors
  bg = '#16191d', -- editor.background, sideBar.background, statusBar.background
  bg_float = '#1e2227', -- editorWidget.background, editorSuggestWidget.background, editorHoverWidget.background
  bg_input = '#1d1f23', -- input.background
  bg_line = '#2c313c', -- editor.lineHighlightBackground
  bg_select = '#2c313a', -- list.activeSelectionBackground, editorSuggestWidget.selectedBackground
  bg_focus = '#323842', -- list.focusBackground, tab.hoverBackground
  bg_tab = '#23272e', -- tab.activeBackground
  border = '#181a1f', -- editorGroup.border, editorSuggestWidget.border, editorHoverWidget.border
  border_focus = '#3e4452', -- focusBorder, panel.border
  border_sidebar = '#37393d', -- sideBar.border
  line_nr = '#667187', -- editorLineNumber.foreground
  cursor = '#528bff', -- editorCursor.foreground
  guide = '#3b4048', -- editorIndentGuide.background1
  bracket_match = '#515a6b', -- editorBracketMatch.background
  git_add = '#109868', -- editorGutter.addedBackground
  git_change = '#948b60', -- editorGutter.modifiedBackground
  git_delete = '#9a353d', -- editorGutter.deletedBackground
  diag_error = '#c24038', -- editorError.foreground
  diag_warn = '#d19a66', -- editorWarning.foreground
  diag_info = '#3794ff', -- VSCode default for editorInfo.foreground; the theme does not set it
  diag_hint = '#7f848e', -- the comment color; VSCode's hint default is an underline color, not for text
  status_fg = '#9da5b4', -- statusBar.foreground
  inactive_fg = '#6b717d', -- titleBar.inactiveForeground
  tab_fg = '#dcdcdc', -- tab.activeForeground
  list_fg = '#d7dae0', -- list.activeSelectionForeground, activityBar.foreground

  -- Blended onto #16191d: result = alpha * color + (1 - alpha) * bg
  selection = '#343c4b', -- editor.selectionBackground #67769660
  search = '#483b30', -- editor.findMatchBackground #d19a6644
  search_other = '#35383b', -- editor.findMatchHighlightBackground #ffffff22
  word_highlight = '#393e47', -- editor.wordHighlightBackground #d2e0ff2f
  diff_add_bg = '#122e36', -- diffEditor.insertedTextBackground #00809b33
  diff_delete_bg = '#451417', -- VSCode default diffEditor.removedTextBackground #ff000033
  diff_change_bg = '#2f302a', -- git_change at 20% (#948b6033); VSCode has no changed-line color
  diff_text_bg = '#484738', -- git_change at 40% (#948b6066)
  indent_active = '#545659', -- editorIndentGuide.activeBackground1 #c8c8c859
  whitespace = '#303337', -- editorWhitespace.foreground #ffffff1d, tree.indentGuidesStroke
  ruler = '#2c3035', -- editorRuler.foreground #abb2bf26
  scrollbar = '#2b3038', -- scrollbarSlider.background #4e566660

  -- terminal.ansi* colors, same as the Ghostty one-dark theme
  terminal = {
    '#3f4451', -- 0 black
    '#e05561', -- 1 red
    '#8cc265', -- 2 green
    '#d18f52', -- 3 yellow
    '#4aa5f0', -- 4 blue
    '#c162de', -- 5 magenta
    '#42b3c2', -- 6 cyan
    '#d7dae0', -- 7 white
    '#4f5666', -- 8 bright black
    '#ff616e', -- 9 bright red
    '#a5e075', -- 10 bright green
    '#f0a45d', -- 11 bright yellow
    '#4dc4ff', -- 12 bright blue
    '#de73ff', -- 13 bright magenta
    '#4cd1e0', -- 14 bright cyan
    '#e6e6e6', -- 15 bright white
  },
}
```

- [ ] **Step 5: Run the palette tests to verify they pass**

Run: `nvim --clean -l lua/custom/plugins/colorscheme/tests/run.lua`
Expected: `3 passed, 0 failed`

- [ ] **Step 6: Write the failing util test**

`lua/custom/plugins/colorscheme/tests/util_spec.lua`:

```lua
local t = require 'helpers'
local util = require 'custom.plugins.colorscheme.util'

t.test('has_plugin finds a module on the runtimepath', function()
  -- The colorscheme module itself is on the runtimepath (tests/run.lua adds the repo root).
  t.ok(util.has_plugin 'custom.plugins.colorscheme', 'own module')
  t.ok(util.has_plugin { 'no.such.plugin', 'custom.plugins.colorscheme.palette' }, 'one of a list')
end)

t.test('has_plugin is false for a missing module', function()
  t.ok(not util.has_plugin 'no.such.plugin', 'missing')
  t.ok(not util.has_plugin { 'no.such.plugin', 'another.missing' }, 'missing list')
end)

t.test('has_plugin is true for a loaded module without files', function()
  package.loaded['fake.loaded.module'] = {}
  t.ok(util.has_plugin 'fake.loaded.module', 'loaded')
  package.loaded['fake.loaded.module'] = nil
end)

t.test('apply sets highlight groups', function()
  util.apply { OnedarkTestGroup = { fg = '#e06c75', bg = '#16191d' } }
  local hl = vim.api.nvim_get_hl(0, { name = 'OnedarkTestGroup' })
  t.eq('#e06c75', t.hex(hl.fg), 'fg')
  t.eq('#16191d', t.hex(hl.bg), 'bg')
end)
```

- [ ] **Step 7: Run the tests to verify the util tests fail**

Run: `nvim --clean -l lua/custom/plugins/colorscheme/tests/run.lua`
Expected: an error `module 'custom.plugins.colorscheme.util' not found`.

- [ ] **Step 8: Write util.lua**

`lua/custom/plugins/colorscheme/util.lua`:

```lua
-- Helpers shared by the colorscheme.
local M = {}

-- True when a plugin is available.
-- `names` is a Lua module name ('telescope', 'blink.cmp') or a list of them.
-- A plugin counts as available when its module is already loaded, or when
-- lua/<name>.lua, lua/<name>/init.lua or lua/<name>/*.lua is on the runtimepath.
---@param names string|string[]
---@return boolean
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
---@param groups table<string, vim.api.keyset.highlight>
function M.apply(groups)
  for name, def in pairs(groups) do
    vim.api.nvim_set_hl(0, name, def)
  end
end

return M
```

- [ ] **Step 9: Run the tests to verify they pass**

Run: `nvim --clean -l lua/custom/plugins/colorscheme/tests/run.lua`
Expected: `7 passed, 0 failed`

- [ ] **Step 10: Check formatting**

Run: `~/.local/share/nvim/mason/bin/stylua --check lua/custom/plugins/colorscheme`
Expected: no output. If it reports a file, run the same command without `--check` and look at the diff.

- [ ] **Step 11: Commit**

```bash
git add lua/custom/plugins/colorscheme
git commit -m "Add the One Dark palette, util helpers and a test runner

Written-by: Claude"
```

---

### Task 3: Core groups: editor, syntax, treesitter, lsp

**Files:**
- Create: `lua/custom/plugins/colorscheme/groups/editor.lua`
- Create: `lua/custom/plugins/colorscheme/groups/syntax.lua`
- Create: `lua/custom/plugins/colorscheme/groups/treesitter.lua`
- Create: `lua/custom/plugins/colorscheme/groups/lsp.lua`
- Create: `lua/custom/plugins/colorscheme/tests/groups_spec.lua`

**Interfaces:**
- Consumes: the palette keys from Task 2, `t.strict`.
- Produces: each file returns `{ get = function(p) return groups end }`. Core file names: `'editor', 'syntax', 'treesitter', 'lsp'`.

- [ ] **Step 1: Write the failing groups test**

`lua/custom/plugins/colorscheme/tests/groups_spec.lua`:

```lua
local t = require 'helpers'
local palette = require 'custom.plugins.colorscheme.palette'

local core = { 'editor', 'syntax', 'treesitter', 'lsp' }

local function is_color(value) return value == 'NONE' or (type(value) == 'string' and value:match '^#%x%x%x%x%x%x$' ~= nil) end

-- Every core file returns groups whose colors come from the palette.
-- The strict palette errors on an unknown key, so a typo like p.purpel fails here.
for _, name in ipairs(core) do
  t.test('groups/' .. name .. ' uses only palette colors', function()
    local groups = require('custom.plugins.colorscheme.groups.' .. name).get(t.strict(palette))
    t.ok(type(groups) == 'table' and next(groups) ~= nil, 'returns a non-empty table')
    for group, def in pairs(groups) do
      t.ok(type(def) == 'table', group .. ' is a table')
      for _, key in ipairs { 'fg', 'bg', 'sp' } do
        if def[key] ~= nil then t.ok(is_color(def[key]), ('%s.%s = %s'):format(group, key, tostring(def[key]))) end
      end
      if def.link then t.ok(type(def.link) == 'string', group .. '.link is a string') end
    end
  end)

  t.test('groups/' .. name .. ' has no bold and no italic', function()
    local groups = require('custom.plugins.colorscheme.groups.' .. name).get(palette)
    for group, def in pairs(groups) do
      t.ok(not def.bold, group .. ' is not bold')
      t.ok(not def.italic, group .. ' is not italic')
    end
  end)
end

t.test('editor groups use the VSCode values', function()
  local g = require('custom.plugins.colorscheme.groups.editor').get(palette)
  t.eq({ fg = palette.fg, bg = palette.bg }, g.Normal, 'Normal')
  t.eq({ bg = palette.bg_line }, g.CursorLine, 'CursorLine')
  t.eq({ fg = palette.line_nr }, g.LineNr, 'LineNr')
  t.eq({ bg = palette.selection }, g.Visual, 'Visual')
  t.eq({ bg = palette.search }, g.CurSearch, 'CurSearch')
  t.eq({ bg = palette.search_other }, g.Search, 'Search')
  t.eq({ fg = palette.fg, bg = palette.bg_float }, g.NormalFloat, 'NormalFloat')
  t.eq({ fg = palette.border, bg = palette.bg_float }, g.FloatBorder, 'FloatBorder')
  t.eq({ fg = palette.status_fg, bg = palette.bg }, g.StatusLine, 'StatusLine')
end)

t.test('syntax groups cover files without a tree-sitter parser', function()
  local g = require('custom.plugins.colorscheme.groups.syntax').get(palette)
  local names = { 'Comment', 'String', 'Number', 'Keyword', 'Function', 'Type', 'Constant', 'Identifier' }
  vim.list_extend(names, { 'Operator', 'Statement', 'PreProc', 'Special', 'Todo', 'Error' })
  for _, name in ipairs(names) do
    t.ok(g[name], name .. ' is defined')
  end
  t.eq({ fg = palette.comment }, g.Comment, 'Comment')
  t.eq({ fg = palette.green }, g.String, 'String')
  t.eq({ fg = palette.purple }, g.Keyword, 'Keyword')
end)

t.test('treesitter captures follow the One Dark mapping', function()
  local g = require('custom.plugins.colorscheme.groups.treesitter').get(palette)
  t.eq({ fg = palette.red }, g['@variable'], '@variable')
  t.eq({ fg = palette.yellow }, g['@variable.builtin'], '@variable.builtin')
  t.eq({ fg = palette.orange }, g['@constant'], '@constant')
  t.eq({ fg = palette.green }, g['@string'], '@string')
  t.eq({ fg = palette.cyan }, g['@string.escape'], '@string.escape')
  t.eq({ fg = palette.blue }, g['@function'], '@function')
  t.eq({ fg = palette.cyan }, g['@function.builtin'], '@function.builtin')
  t.eq({ fg = palette.purple }, g['@keyword'], '@keyword')
  t.eq({ fg = palette.purple }, g['@keyword.operator'], '@keyword.operator')
  t.eq({ fg = palette.cyan }, g['@operator'], '@operator')
  t.eq({ fg = palette.fg }, g['@punctuation.bracket'], '@punctuation.bracket')
  t.eq({ fg = palette.yellow }, g['@type'], '@type')
  t.eq({ fg = palette.red }, g['@tag'], '@tag')
  t.eq({ fg = palette.orange }, g['@tag.attribute'], '@tag.attribute')
  t.eq({ fg = palette.red }, g['@markup.heading'], '@markup.heading')
  t.eq({ fg = palette.purple, underline = true }, g['@markup.link.url'], '@markup.link.url')
  t.eq({ fg = palette.cyan }, g['@boolean.json'], '@boolean.json')
  t.eq({ fg = palette.fg }, g['@property.css'], '@property.css')
end)

t.test('lsp tokens and diagnostics follow the One Dark mapping', function()
  local g = require('custom.plugins.colorscheme.groups.lsp').get(palette)
  t.eq({ fg = palette.yellow }, g['@lsp.typemod.variable.readonly'], 'readonly')
  t.eq({ fg = palette.yellow }, g['@lsp.typemod.variable.defaultLibrary'], 'defaultLibrary')
  t.eq({ fg = palette.cyan }, g['@lsp.typemod.function.defaultLibrary'], 'function.defaultLibrary')
  t.eq({ fg = palette.cyan }, g['@lsp.type.enumMember'], 'enumMember')
  t.eq({ fg = palette.diag_error }, g.DiagnosticError, 'DiagnosticError')
  t.eq({ sp = palette.diag_warn, undercurl = true }, g.DiagnosticUnderlineWarn, 'DiagnosticUnderlineWarn')
end)
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `nvim --clean -l lua/custom/plugins/colorscheme/tests/run.lua 2>&1 | grep -c FAIL`
Expected: a number greater than 0 (the `groups/...` modules are not found).

- [ ] **Step 3: Write editor.lua**

`lua/custom/plugins/colorscheme/groups/editor.lua`:

```lua
-- Built-in UI groups. See :help highlight-groups.
-- The VSCode key for each color is in palette.lua.
local M = {}

---@param p table palette
---@return table<string, vim.api.keyset.highlight>
function M.get(p)
  return {
    Normal = { fg = p.fg, bg = p.bg },
    NormalNC = { fg = p.fg, bg = p.bg },
    NormalFloat = { fg = p.fg, bg = p.bg_float },
    FloatBorder = { fg = p.border, bg = p.bg_float },
    FloatTitle = { fg = p.blue, bg = p.bg_float },
    FloatFooter = { fg = p.comment, bg = p.bg_float },

    -- Cursor and current line
    Cursor = { fg = p.bg, bg = p.cursor },
    lCursor = { fg = p.bg, bg = p.cursor },
    CursorIM = { fg = p.bg, bg = p.cursor },
    TermCursor = { fg = p.bg, bg = p.cursor },
    CursorLine = { bg = p.bg_line },
    CursorColumn = { bg = p.bg_line },
    QuickFixLine = { bg = p.bg_line },
    ColorColumn = { bg = p.ruler },

    -- Gutter
    LineNr = { fg = p.line_nr },
    LineNrAbove = { fg = p.line_nr },
    LineNrBelow = { fg = p.line_nr },
    CursorLineNr = { fg = p.fg },
    SignColumn = { bg = p.bg },
    CursorLineSign = { bg = p.bg_line },
    FoldColumn = { fg = p.line_nr, bg = p.bg },
    CursorLineFold = { fg = p.line_nr, bg = p.bg_line },
    Folded = { fg = p.comment, bg = p.bg_float },

    -- Selection and search
    Visual = { bg = p.selection },
    VisualNOS = { bg = p.selection },
    Search = { bg = p.search_other },
    CurSearch = { bg = p.search },
    IncSearch = { bg = p.search },
    Substitute = { bg = p.search },
    MatchParen = { bg = p.bracket_match },

    -- Invisible characters
    Whitespace = { fg = p.whitespace },
    NonText = { fg = p.whitespace },
    EndOfBuffer = { fg = p.whitespace },
    SpecialKey = { fg = p.whitespace },
    Conceal = { fg = p.comment },

    -- Popup menu
    Pmenu = { fg = p.fg, bg = p.bg_float },
    PmenuSel = { bg = p.bg_select },
    PmenuKind = { fg = p.comment, bg = p.bg_float },
    PmenuKindSel = { fg = p.comment, bg = p.bg_select },
    PmenuExtra = { fg = p.comment, bg = p.bg_float },
    PmenuExtraSel = { fg = p.comment, bg = p.bg_select },
    PmenuSbar = { bg = p.bg_float },
    PmenuThumb = { bg = p.scrollbar },
    PmenuMatch = { fg = p.blue, bg = p.bg_float },
    PmenuMatchSel = { fg = p.blue, bg = p.bg_select },
    WildMenu = { bg = p.bg_select },

    -- Status line, tabs, splits
    StatusLine = { fg = p.status_fg, bg = p.bg },
    StatusLineNC = { fg = p.inactive_fg, bg = p.bg },
    StatusLineTerm = { fg = p.status_fg, bg = p.bg },
    StatusLineTermNC = { fg = p.inactive_fg, bg = p.bg },
    WinSeparator = { fg = p.border },
    VertSplit = { fg = p.border },
    TabLine = { fg = p.inactive_fg, bg = p.bg },
    TabLineFill = { bg = p.bg },
    TabLineSel = { fg = p.tab_fg, bg = p.bg_tab },
    WinBar = { fg = p.fg, bg = p.bg },
    WinBarNC = { fg = p.inactive_fg, bg = p.bg },

    -- Messages
    Title = { fg = p.blue },
    Directory = { fg = p.blue },
    ErrorMsg = { fg = p.diag_error },
    WarningMsg = { fg = p.diag_warn },
    MoreMsg = { fg = p.green },
    Question = { fg = p.green },
    ModeMsg = { fg = p.fg },
    MsgArea = { fg = p.fg },
    MsgSeparator = { fg = p.border },

    -- Diff
    DiffAdd = { bg = p.diff_add_bg },
    DiffDelete = { bg = p.diff_delete_bg },
    DiffChange = { bg = p.diff_change_bg },
    DiffText = { bg = p.diff_text_bg },
    Added = { fg = p.green },
    Changed = { fg = p.yellow },
    Removed = { fg = p.red },

    -- Spelling
    SpellBad = { sp = p.diag_error, undercurl = true },
    SpellCap = { sp = p.diag_warn, undercurl = true },
    SpellLocal = { sp = p.diag_info, undercurl = true },
    SpellRare = { sp = p.diag_hint, undercurl = true },

    -- Misc
    Underlined = { underline = true },
    Error = { fg = p.error },
    Ignore = { fg = p.bg },
    healthSuccess = { fg = p.green },
    healthWarning = { fg = p.diag_warn },
    healthError = { fg = p.diag_error },
  }
end

return M
```

- [ ] **Step 4: Write syntax.lua**

`lua/custom/plugins/colorscheme/groups/syntax.lua`:

```lua
-- Classic Vim syntax groups. See :help group-name.
-- Used for file types without a tree-sitter parser.
local M = {}

---@param p table palette
---@return table<string, vim.api.keyset.highlight>
function M.get(p)
  return {
    Comment = { fg = p.comment },
    SpecialComment = { fg = p.comment },

    Constant = { fg = p.orange },
    String = { fg = p.green },
    Character = { fg = p.green },
    Number = { fg = p.orange },
    Boolean = { fg = p.orange },
    Float = { fg = p.orange },

    Identifier = { fg = p.red },
    Function = { fg = p.blue },

    Statement = { fg = p.purple },
    Conditional = { fg = p.purple },
    Repeat = { fg = p.purple },
    Label = { fg = p.red },
    Operator = { fg = p.cyan },
    Keyword = { fg = p.purple },
    Exception = { fg = p.purple },

    PreProc = { fg = p.purple },
    Include = { fg = p.purple },
    Define = { fg = p.purple },
    Macro = { fg = p.orange },
    PreCondit = { fg = p.purple },

    Type = { fg = p.yellow },
    StorageClass = { fg = p.purple },
    Structure = { fg = p.yellow },
    Typedef = { fg = p.yellow },

    Special = { fg = p.cyan },
    SpecialChar = { fg = p.cyan },
    Tag = { fg = p.red },
    Delimiter = { fg = p.fg },
    Debug = { fg = p.purple },

    Todo = { fg = p.blue },
    Error = { fg = p.error },
  }
end

return M
```

- [ ] **Step 5: Write treesitter.lua**

`lua/custom/plugins/colorscheme/groups/treesitter.lua`:

```lua
-- Tree-sitter captures. See :help treesitter-highlight-groups.
-- Each capture maps to the TextMate scope VSCode uses for the same thing.
-- Language-specific captures (@property.css, @boolean.json, ...) reproduce
-- the language rules of the VSCode theme.
local M = {}

---@param p table palette
---@return table<string, vim.api.keyset.highlight>
function M.get(p)
  return {
    -- Variables: TextMate "variable" is red
    ['@variable'] = { fg = p.red },
    ['@variable.builtin'] = { fg = p.yellow }, -- variable.language: this, self, vim
    ['@variable.parameter'] = { fg = p.red },
    ['@variable.parameter.builtin'] = { fg = p.yellow },
    ['@variable.member'] = { fg = p.red },
    ['@property'] = { fg = p.red },

    -- Constants
    ['@constant'] = { fg = p.orange },
    ['@constant.builtin'] = { fg = p.orange }, -- constant.language: true, null, nil
    ['@constant.macro'] = { fg = p.orange },

    -- Literals
    ['@number'] = { fg = p.orange },
    ['@number.float'] = { fg = p.orange },
    ['@boolean'] = { fg = p.orange },
    ['@string'] = { fg = p.green },
    ['@string.documentation'] = { fg = p.comment },
    ['@string.regexp'] = { fg = p.red }, -- string.regexp: the last rule in the theme wins
    ['@string.escape'] = { fg = p.cyan }, -- constant.character.escape
    ['@string.special'] = { fg = p.green },
    ['@string.special.symbol'] = { fg = p.cyan },
    ['@string.special.path'] = { fg = p.green },
    ['@string.special.url'] = { fg = p.purple, underline = true },
    ['@character'] = { fg = p.green },
    ['@character.special'] = { fg = p.cyan },

    -- Functions
    ['@function'] = { fg = p.blue },
    ['@function.builtin'] = { fg = p.cyan }, -- support.function
    ['@function.call'] = { fg = p.blue },
    ['@function.macro'] = { fg = p.blue },
    ['@function.method'] = { fg = p.blue },
    ['@function.method.call'] = { fg = p.blue },
    ['@constructor'] = { fg = p.blue },

    -- Keywords
    ['@keyword'] = { fg = p.purple },
    ['@keyword.coroutine'] = { fg = p.purple },
    ['@keyword.function'] = { fg = p.purple },
    ['@keyword.operator'] = { fg = p.purple }, -- keyword.operator.word: and, or, not, new, typeof
    ['@keyword.import'] = { fg = p.purple },
    ['@keyword.type'] = { fg = p.purple },
    ['@keyword.modifier'] = { fg = p.purple },
    ['@keyword.repeat'] = { fg = p.purple },
    ['@keyword.return'] = { fg = p.purple },
    ['@keyword.debug'] = { fg = p.purple },
    ['@keyword.exception'] = { fg = p.purple },
    ['@keyword.conditional'] = { fg = p.purple },
    ['@keyword.conditional.ternary'] = { fg = p.purple },
    ['@keyword.directive'] = { fg = p.purple },
    ['@keyword.directive.define'] = { fg = p.purple },

    -- Operators and punctuation
    ['@operator'] = { fg = p.cyan }, -- keyword.operator.arithmetic, .comparison, .logical, .assignment
    ['@punctuation.delimiter'] = { fg = p.fg },
    ['@punctuation.bracket'] = { fg = p.fg },
    ['@punctuation.special'] = { fg = p.purple }, -- template expression ${ }

    -- Types
    ['@type'] = { fg = p.yellow },
    ['@type.builtin'] = { fg = p.yellow },
    ['@type.definition'] = { fg = p.yellow },
    ['@attribute'] = { fg = p.blue }, -- decorators
    ['@attribute.builtin'] = { fg = p.blue },
    ['@module'] = { fg = p.yellow },
    ['@module.builtin'] = { fg = p.yellow },
    ['@namespace'] = { fg = p.yellow },
    ['@label'] = { fg = p.red },

    -- Comments
    ['@comment'] = { fg = p.comment },
    ['@comment.documentation'] = { fg = p.comment },
    ['@comment.error'] = { fg = p.diag_error },
    ['@comment.warning'] = { fg = p.diag_warn },
    ['@comment.todo'] = { fg = p.blue },
    ['@comment.note'] = { fg = p.cyan },

    -- Markup
    ['@markup.strong'] = { fg = p.orange },
    ['@markup.italic'] = { fg = p.purple },
    ['@markup.strikethrough'] = { strikethrough = true },
    ['@markup.underline'] = { underline = true },
    ['@markup.heading'] = { fg = p.red },
    ['@markup.heading.1'] = { fg = p.red },
    ['@markup.heading.2'] = { fg = p.red },
    ['@markup.heading.3'] = { fg = p.red },
    ['@markup.heading.4'] = { fg = p.red },
    ['@markup.heading.5'] = { fg = p.red },
    ['@markup.heading.6'] = { fg = p.red },
    ['@markup.quote'] = { fg = p.dim },
    ['@markup.math'] = { fg = p.blue },
    ['@markup.link'] = { fg = p.blue },
    ['@markup.link.label'] = { fg = p.blue },
    ['@markup.link.url'] = { fg = p.purple, underline = true },
    ['@markup.raw'] = { fg = p.green },
    ['@markup.raw.block'] = { fg = p.green },
    ['@markup.list'] = { fg = p.yellow },
    ['@markup.list.checked'] = { fg = p.green },
    ['@markup.list.unchecked'] = { fg = p.yellow },

    -- Diff
    ['@diff.plus'] = { fg = p.green },
    ['@diff.minus'] = { fg = p.red },
    ['@diff.delta'] = { fg = p.yellow },

    -- Tags (HTML, JSX)
    ['@tag'] = { fg = p.red },
    ['@tag.builtin'] = { fg = p.red },
    ['@tag.attribute'] = { fg = p.orange },
    ['@tag.delimiter'] = { fg = p.fg },

    -- CSS
    ['@property.css'] = { fg = p.fg }, -- support.type.property-name
    ['@property.scss'] = { fg = p.fg },
    ['@tag.css'] = { fg = p.red }, -- entity.name.tag selector
    ['@tag.scss'] = { fg = p.red },
    ['@property.class.css'] = { fg = p.orange }, -- .class selector
    ['@property.id.css'] = { fg = p.blue }, -- #id selector
    ['@attribute.css'] = { fg = p.cyan }, -- :hover, ::before
    ['@attribute.scss'] = { fg = p.cyan },
    ['@constant.css'] = { fg = p.orange }, -- property value keywords: flex, red
    ['@string.special.css'] = { fg = p.orange }, -- #fff
    ['@keyword.import.css'] = { fg = p.purple },
    ['@number.css'] = { fg = p.orange },
    ['@type.css'] = { fg = p.red }, -- units: px, %

    -- HTML
    ['@character.special.html'] = { fg = p.red }, -- &amp;
    ['@string.special.url.html'] = { fg = p.green },

    -- JSON
    ['@property.json'] = { fg = p.red },
    ['@boolean.json'] = { fg = p.cyan },
    ['@constant.builtin.json'] = { fg = p.cyan },
    ['@property.jsonc'] = { fg = p.red },
    ['@boolean.jsonc'] = { fg = p.cyan },
    ['@constant.builtin.jsonc'] = { fg = p.cyan },

    -- Markdown punctuation: #, -, `, *
    ['@punctuation.special.markdown'] = { fg = p.red },
    ['@markup.list.markdown'] = { fg = p.yellow },
    ['@punctuation.delimiter.markdown_inline'] = { fg = p.yellow },
    ['@label.markdown'] = { fg = p.yellow }, -- code fence language name
    ['@conceal.markdown_inline'] = { fg = p.yellow },
  }
end

return M
```

The CSS capture names (`@property.class.css`, `@property.id.css`, `@type.css`, `@attribute.css`) are what nvim-treesitter's `css` queries produce. Task 7 confirms them with `:Inspect`.

- [ ] **Step 6: Write lsp.lua**

`lua/custom/plugins/colorscheme/groups/lsp.lua`:

```lua
-- LSP semantic tokens (:help lsp-semantic-highlight) and diagnostics.
-- VSCode maps each semantic token to a TextMate scope; the colors follow that.
local M = {}

---@param p table palette
---@return table<string, vim.api.keyset.highlight>
function M.get(p)
  return {
    -- Semantic token types
    ['@lsp.type.class'] = { fg = p.yellow },
    ['@lsp.type.comment'] = { fg = p.comment },
    ['@lsp.type.decorator'] = { fg = p.blue },
    ['@lsp.type.enum'] = { fg = p.yellow },
    ['@lsp.type.enumMember'] = { fg = p.cyan }, -- semanticTokenColors.enumMember
    ['@lsp.type.event'] = { fg = p.red },
    ['@lsp.type.function'] = { fg = p.blue },
    ['@lsp.type.interface'] = { fg = p.yellow },
    ['@lsp.type.keyword'] = { fg = p.purple },
    ['@lsp.type.macro'] = { fg = p.orange }, -- semanticTokenColors.macro
    ['@lsp.type.method'] = { fg = p.blue },
    ['@lsp.type.modifier'] = { fg = p.purple },
    ['@lsp.type.namespace'] = { fg = p.yellow },
    ['@lsp.type.number'] = { fg = p.orange },
    ['@lsp.type.operator'] = { fg = p.cyan },
    ['@lsp.type.parameter'] = { fg = p.red },
    ['@lsp.type.property'] = { fg = p.red },
    ['@lsp.type.regexp'] = { fg = p.red },
    ['@lsp.type.string'] = { fg = p.green },
    ['@lsp.type.struct'] = { fg = p.yellow },
    ['@lsp.type.type'] = { fg = p.yellow },
    ['@lsp.type.typeParameter'] = { fg = p.yellow },
    ['@lsp.type.variable'] = { fg = p.red },

    -- Modifiers. Neovim gives these a higher priority than the type groups.
    ['@lsp.typemod.variable.readonly'] = { fg = p.yellow }, -- variable.readonly -> variable.other.constant
    ['@lsp.typemod.variable.defaultLibrary'] = { fg = p.yellow }, -- semanticTokenColors variable.defaultLibrary
    ['@lsp.typemod.variable.global'] = { fg = p.red },
    ['@lsp.typemod.property.readonly'] = { fg = p.red },
    ['@lsp.typemod.function.defaultLibrary'] = { fg = p.cyan }, -- support.function
    ['@lsp.typemod.method.defaultLibrary'] = { fg = p.cyan },
    ['@lsp.typemod.class.defaultLibrary'] = { fg = p.yellow },
    ['@lsp.typemod.type.defaultLibrary'] = { fg = p.yellow },
    ['@lsp.typemod.function.declaration'] = { fg = p.blue },
    ['@lsp.typemod.method.declaration'] = { fg = p.blue },
    ['@lsp.typemod.variable.declaration'] = { fg = p.red },
    ['@lsp.typemod.parameter.declaration'] = { fg = p.red },

    -- Diagnostics
    DiagnosticError = { fg = p.diag_error },
    DiagnosticWarn = { fg = p.diag_warn },
    DiagnosticInfo = { fg = p.diag_info },
    DiagnosticHint = { fg = p.diag_hint },
    DiagnosticOk = { fg = p.green },
    DiagnosticVirtualTextError = { fg = p.diag_error },
    DiagnosticVirtualTextWarn = { fg = p.diag_warn },
    DiagnosticVirtualTextInfo = { fg = p.diag_info },
    DiagnosticVirtualTextHint = { fg = p.diag_hint },
    DiagnosticVirtualTextOk = { fg = p.green },
    DiagnosticUnderlineError = { sp = p.diag_error, undercurl = true },
    DiagnosticUnderlineWarn = { sp = p.diag_warn, undercurl = true },
    DiagnosticUnderlineInfo = { sp = p.diag_info, undercurl = true },
    DiagnosticUnderlineHint = { sp = p.diag_hint, undercurl = true },
    DiagnosticUnderlineOk = { sp = p.green, undercurl = true },
    DiagnosticFloatingError = { fg = p.diag_error, bg = p.bg_float },
    DiagnosticFloatingWarn = { fg = p.diag_warn, bg = p.bg_float },
    DiagnosticFloatingInfo = { fg = p.diag_info, bg = p.bg_float },
    DiagnosticFloatingHint = { fg = p.diag_hint, bg = p.bg_float },
    DiagnosticFloatingOk = { fg = p.green, bg = p.bg_float },
    DiagnosticSignError = { fg = p.diag_error },
    DiagnosticSignWarn = { fg = p.diag_warn },
    DiagnosticSignInfo = { fg = p.diag_info },
    DiagnosticSignHint = { fg = p.diag_hint },
    DiagnosticSignOk = { fg = p.green },
    DiagnosticDeprecated = { sp = p.comment, strikethrough = true },
    DiagnosticUnnecessary = { fg = p.comment },

    -- LSP UI
    LspReferenceText = { bg = p.word_highlight },
    LspReferenceRead = { bg = p.word_highlight },
    LspReferenceWrite = { bg = p.word_highlight },
    LspReferenceTarget = { bg = p.word_highlight },
    LspInlayHint = { fg = p.fg, bg = p.bg_line }, -- editorInlayHint.foreground / background
    LspCodeLens = { fg = p.comment },
    LspCodeLensSeparator = { fg = p.comment },
    LspSignatureActiveParameter = { bg = p.word_highlight },
  }
end

return M
```

- [ ] **Step 7: Run the tests to verify they pass**

Run: `nvim --clean -l lua/custom/plugins/colorscheme/tests/run.lua`
Expected: `19 passed, 0 failed`

- [ ] **Step 8: Check formatting**

Run: `~/.local/share/nvim/mason/bin/stylua --check lua/custom/plugins/colorscheme`
Expected: no output.

- [ ] **Step 9: Commit**

```bash
git add lua/custom/plugins/colorscheme
git commit -m "Add the One Dark core highlight groups

Editor UI, classic syntax groups, tree-sitter captures and LSP tokens,
each mapped to the TextMate scope the VSCode theme uses.

Written-by: Claude"
```

---

### Task 4: The loader, init.lua wiring, and CI

**Files:**
- Create: `lua/custom/plugins/colorscheme/init.lua`
- Create: `lua/custom/plugins/colorscheme/tests/startup_spec.lua`
- Create: `.github/workflows/colorscheme-tests.yml`
- Modify: `init.lua` (the `[[ Colorscheme ]]` comment left by Task 1)

**Interfaces:**
- Consumes: `palette`, `util.has_plugin`, `util.apply`, the core group files from Task 3.
- Produces: `M.load()`, `M.apply_new_integrations(): boolean`, `M.integrations` (list of names). Integration files (Task 5 and 6) must export `detect` and `get(p)`.

- [ ] **Step 1: Write the failing startup test**

`lua/custom/plugins/colorscheme/tests/startup_spec.lua`:

```lua
local t = require 'helpers'
local palette = require 'custom.plugins.colorscheme.palette'

local function fresh()
  t.unload 'custom.plugins.colorscheme'
  -- The group exists only after the first load, so ignore the error.
  pcall(vim.api.nvim_clear_autocmds, { group = 'onedark-startup' })
  return require 'custom.plugins.colorscheme'
end

-- Number of autocmds in the startup group; 0 when the group does not exist.
local function startup_autocmds()
  local ok, list = pcall(vim.api.nvim_get_autocmds, { group = 'onedark-startup' })
  return ok and #list or 0
end

t.test('requiring the module applies the theme', function()
  fresh()
  t.eq('onedark', vim.g.colors_name, 'colors_name')
  local normal = vim.api.nvim_get_hl(0, { name = 'Normal' })
  t.eq(palette.fg, t.hex(normal.fg), 'Normal fg')
  t.eq(palette.bg, t.hex(normal.bg), 'Normal bg')
  local keyword = vim.api.nvim_get_hl(0, { name = '@keyword' })
  t.eq(palette.purple, t.hex(keyword.fg), '@keyword fg')
end)

t.test('terminal colors are set', function()
  fresh()
  for i = 0, 15 do
    t.eq(palette.terminal[i + 1], vim.g['terminal_color_' .. i], 'terminal_color_' .. i)
  end
end)

t.test('requiring the module twice works and keeps one autocmd group', function()
  fresh()
  t.unload 'custom.plugins.colorscheme'
  require 'custom.plugins.colorscheme'
  t.eq('onedark', vim.g.colors_name, 'colors_name')
  local count = startup_autocmds()
  t.ok(count <= 1, 'at most one VimEnter autocmd, got ' .. count)
end)

t.test('a plugin added later gets its groups from apply_new_integrations', function()
  local M = fresh()
  -- Before: telescope is not on the runtimepath, so its groups are not set.
  t.eq(nil, vim.api.nvim_get_hl(0, { name = 'TelescopeSelection' }).bg, 'no telescope group yet')

  -- Simulate a plugin that appears after the theme ran.
  local dir = vim.fn.tempname()
  vim.fn.mkdir(dir .. '/lua/telescope', 'p')
  vim.fn.writefile({ 'return {}' }, dir .. '/lua/telescope/init.lua')
  vim.opt.runtimepath:append(dir)

  t.ok(M.apply_new_integrations(), 'reports that something was added')
  t.eq(palette.bg_select, t.hex(vim.api.nvim_get_hl(0, { name = 'TelescopeSelection' }).bg), 'TelescopeSelection bg')
  t.ok(not M.apply_new_integrations(), 'second call adds nothing')

  vim.opt.runtimepath:remove(dir)
  vim.fn.delete(dir, 'rf')
end)

t.test('a broken integration does not stop the theme', function()
  local M = fresh()
  local dir = vim.fn.tempname()
  -- A fake plugin "brokenplug" and a broken group file for it.
  vim.fn.mkdir(dir .. '/lua/brokenplug', 'p')
  vim.fn.writefile({ 'return {}' }, dir .. '/lua/brokenplug/init.lua')
  vim.fn.mkdir(dir .. '/lua/custom/plugins/colorscheme/groups', 'p')
  local broken = "return { detect = 'brokenplug', get = function() error 'boom' end }"
  vim.fn.writefile({ broken }, dir .. '/lua/custom/plugins/colorscheme/groups/brokenplug.lua')
  vim.opt.runtimepath:append(dir)
  table.insert(M.integrations, 'brokenplug')

  local messages = {}
  local notify = vim.notify
  vim.notify = function(msg, level) messages[#messages + 1] = { msg = msg, level = level } end
  local ok = pcall(M.load)
  M.apply_new_integrations()
  vim.notify = notify

  t.ok(ok, 'load() did not raise')
  t.eq('onedark', vim.g.colors_name, 'theme still applied')
  t.eq(1, #messages, 'error reported once')
  t.ok(messages[1].msg:find 'brokenplug', 'message names the integration')
  t.eq(vim.log.levels.ERROR, messages[1].level, 'error level')

  table.remove(M.integrations)
  vim.opt.runtimepath:remove(dir)
  vim.fn.delete(dir, 'rf')
  t.unload 'custom.plugins.colorscheme.groups.brokenplug'
end)
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `nvim --clean -l lua/custom/plugins/colorscheme/tests/run.lua 2>&1 | grep -c FAIL`
Expected: `5` (the module `custom.plugins.colorscheme` has no init.lua yet, and the telescope group file does not exist yet).

- [ ] **Step 3: Write the loader**

`lua/custom/plugins/colorscheme/init.lua`:

```lua
-- One Dark Pro Night Flat colorscheme for Neovim.
-- Requiring this module applies the theme. There are no options.
-- Colors: palette.lua. Highlight groups: groups/*.lua.
local M = {}

local root = 'custom.plugins.colorscheme'

-- Always applied.
local core = { 'editor', 'syntax', 'treesitter', 'lsp' }

-- Applied when the plugin is found on the runtimepath.
-- Each groups/<name>.lua exports `detect` (module names for util.has_plugin) and `get(p)`.
M.integrations = { 'telescope', 'blink', 'gitsigns', 'which_key', 'todo_comments', 'mini', 'fidget', 'mason', 'indent_blankline', 'neo_tree', 'dap' }

-- Integrations applied since the last load(), and ones that failed (so the error is reported once).
local done = {}

-- Apply the groups of every detected integration that was not applied yet.
-- Returns true when at least one integration was added.
---@return boolean
function M.apply_new_integrations()
  local p = require(root .. '.palette')
  local util = require(root .. '.util')
  local added = false
  for _, name in ipairs(M.integrations) do
    if not done[name] then
      local ok, result = pcall(function()
        local mod = require(root .. '.groups.' .. name)
        if not util.has_plugin(mod.detect) then return false end
        util.apply(mod.get(p))
        return true
      end)
      if not ok then
        done[name] = true
        vim.notify(('colorscheme: integration "%s" failed: %s'):format(name, result), vim.log.levels.ERROR)
      elseif result then
        done[name] = true
        added = true
      end
    end
  end
  return added
end

-- Plugins are usually added to the runtimepath after this module ran in init.lua,
-- so detection misses them. Check again at VimEnter, when every plugin is there.
local function reapply_after_startup()
  if vim.v.vim_did_enter == 1 then return end
  vim.api.nvim_create_autocmd('VimEnter', {
    group = vim.api.nvim_create_augroup('onedark-startup', { clear = true }),
    once = true,
    desc = 'Apply colorscheme groups for plugins loaded after the theme',
    callback = function()
      if vim.g.colors_name == 'onedark' then M.apply_new_integrations() end
    end,
  })
end

-- Apply the whole theme.
function M.load()
  local p = require(root .. '.palette')
  local util = require(root .. '.util')

  vim.cmd 'highlight clear'
  vim.g.colors_name = 'onedark'

  for _, name in ipairs(core) do
    util.apply(require(root .. '.groups.' .. name).get(p))
  end

  for i, color in ipairs(p.terminal) do
    vim.g['terminal_color_' .. (i - 1)] = color
  end

  done = {}
  M.apply_new_integrations()
  reapply_after_startup()
end

M.load()

return M
```

- [ ] **Step 4: Write a minimal telescope group file so the startup test can run**

The full telescope file comes in Task 5. For now create `lua/custom/plugins/colorscheme/groups/telescope.lua` with the final `detect` and the one group the test checks; Task 5 replaces the body.

```lua
-- telescope.nvim
local M = {}

M.detect = 'telescope'

---@param p table palette
---@return table<string, vim.api.keyset.highlight>
function M.get(p)
  return {
    TelescopeSelection = { bg = p.bg_select },
  }
end

return M
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `nvim --clean -l lua/custom/plugins/colorscheme/tests/run.lua`
Expected: `24 passed, 0 failed`

If `requiring the module twice` fails on the autocmd count, check that `nvim_create_augroup` uses `clear = true`.

- [ ] **Step 6: Wire the module in init.lua**

Replace the comment block left by Task 1 in `init.lua`:

```lua
  -- [[ Colorscheme ]]
  -- One Dark Pro Night Flat, built from the VSCode theme. See lua/custom/plugins/colorscheme/.
  -- The module does not exist yet; the next commits add it.
```

with:

```lua
  -- [[ Colorscheme ]]
  -- One Dark Pro Night Flat, built from the VSCode theme. See lua/custom/plugins/colorscheme/.
  -- Requiring the module applies the theme. Plugins loaded later in this file are picked up at VimEnter.
  require 'custom.plugins.colorscheme'
```

- [ ] **Step 7: Check that the real config loads the theme and the integrations**

Run:

```bash
nvim --headless "+lua vim.schedule(function() print(vim.g.colors_name, vim.api.nvim_get_hl(0, { name = 'TelescopeSelection' }).bg ~= nil, vim.api.nvim_get_hl(0, { name = 'GitSignsAdd' }).fg ~= nil) vim.cmd 'qa!' end)" 2>&1 | tail -2
```

Expected: `onedark true false` (telescope groups are set at VimEnter; gitsigns groups come in Task 5 and will print `true` after it). No error lines.

- [ ] **Step 8: Add the CI workflow**

`.github/workflows/colorscheme-tests.yml`:

```yaml
# Run the colorscheme tests on the stable Neovim release.
name: Colorscheme tests
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
        run: nvim --clean -l lua/custom/plugins/colorscheme/tests/run.lua
```

- [ ] **Step 9: Check formatting**

Run: `~/.local/share/nvim/mason/bin/stylua --check lua/custom/plugins/colorscheme init.lua`
Expected: no output.

- [ ] **Step 10: Commit**

```bash
git add lua/custom/plugins/colorscheme init.lua .github/workflows/colorscheme-tests.yml
git commit -m "Load the One Dark colorscheme from init.lua and run its tests in CI

The loader applies the core groups, detects plugins, sets the terminal
colors and checks for plugins again at VimEnter. A failing integration
is reported once and does not stop the theme.

Written-by: Claude"
```

---

### Task 5: Integrations: telescope, blink, gitsigns, which-key, todo-comments, mini

**Files:**
- Modify: `lua/custom/plugins/colorscheme/groups/telescope.lua` (replace the body from Task 4)
- Create: `lua/custom/plugins/colorscheme/groups/blink.lua`
- Create: `lua/custom/plugins/colorscheme/groups/gitsigns.lua`
- Create: `lua/custom/plugins/colorscheme/groups/which_key.lua`
- Create: `lua/custom/plugins/colorscheme/groups/todo_comments.lua`
- Create: `lua/custom/plugins/colorscheme/groups/mini.lua`
- Create: `lua/custom/plugins/colorscheme/tests/integrations_spec.lua`

**Interfaces:**
- Consumes: palette keys, `M.integrations` from Task 4.
- Produces: each file exports `detect` (string or list) and `get(p)`.

- [ ] **Step 1: Write the failing integrations test**

`lua/custom/plugins/colorscheme/tests/integrations_spec.lua`:

```lua
local t = require 'helpers'
local palette = require 'custom.plugins.colorscheme.palette'
local M = require 'custom.plugins.colorscheme'

local function is_color(value) return value == 'NONE' or (type(value) == 'string' and value:match '^#%x%x%x%x%x%x$' ~= nil) end

t.test('the integration list has every expected plugin', function()
  local expected = { 'telescope', 'blink', 'gitsigns', 'which_key', 'todo_comments', 'mini', 'fidget', 'mason', 'indent_blankline', 'neo_tree', 'dap' }
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
  }
  for name, detect in pairs(expected) do
    t.eq(detect, require('custom.plugins.colorscheme.groups.' .. name).detect, name .. '.detect')
  end
end)
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `nvim --clean -l lua/custom/plugins/colorscheme/tests/run.lua 2>&1 | grep FAIL | head`
Expected: failures for `blink`, `gitsigns`, `which_key`, `todo_comments`, `mini`, `fidget`, `mason`, `indent_blankline`, `neo_tree`, `dap` (module not found) and the detect test.

- [ ] **Step 3: Write telescope.lua (full)**

Replace the whole file `lua/custom/plugins/colorscheme/groups/telescope.lua`:

```lua
-- telescope.nvim. Mirrors the VSCode quick-open widget: editorWidget background, suggest border.
local M = {}

M.detect = 'telescope'

---@param p table palette
---@return table<string, vim.api.keyset.highlight>
function M.get(p)
  return {
    TelescopeNormal = { fg = p.fg, bg = p.bg_float },
    TelescopeBorder = { fg = p.border, bg = p.bg_float },
    TelescopeTitle = { fg = p.blue, bg = p.bg_float },

    TelescopePromptNormal = { fg = p.fg, bg = p.bg_input },
    TelescopePromptBorder = { fg = p.border, bg = p.bg_input },
    TelescopePromptTitle = { fg = p.blue, bg = p.bg_input },
    TelescopePromptPrefix = { fg = p.blue, bg = p.bg_input },
    TelescopePromptCounter = { fg = p.comment, bg = p.bg_input },

    TelescopeResultsNormal = { fg = p.fg, bg = p.bg_float },
    TelescopeResultsBorder = { fg = p.border, bg = p.bg_float },
    TelescopeResultsTitle = { fg = p.blue, bg = p.bg_float },
    TelescopeResultsComment = { fg = p.comment },
    TelescopeResultsLineNr = { fg = p.line_nr },

    TelescopePreviewNormal = { fg = p.fg, bg = p.bg_float },
    TelescopePreviewBorder = { fg = p.border, bg = p.bg_float },
    TelescopePreviewTitle = { fg = p.blue, bg = p.bg_float },
    TelescopePreviewLine = { bg = p.bg_line },
    TelescopePreviewMatch = { bg = p.search },

    TelescopeSelection = { bg = p.bg_select },
    TelescopeSelectionCaret = { fg = p.blue, bg = p.bg_select },
    TelescopeMultiSelection = { fg = p.list_fg, bg = p.bg_focus },
    TelescopeMultiIcon = { fg = p.blue },
    TelescopeMatching = { fg = p.blue },

    TelescopeResultsDiffAdd = { fg = p.green },
    TelescopeResultsDiffChange = { fg = p.yellow },
    TelescopeResultsDiffDelete = { fg = p.red },
    TelescopeResultsDiffUntracked = { fg = p.comment },
  }
end

return M
```

- [ ] **Step 4: Write blink.lua**

`lua/custom/plugins/colorscheme/groups/blink.lua`:

```lua
-- blink.cmp. Mirrors the VSCode suggest widget. Kind colors follow the syntax colors.
local M = {}

M.detect = 'blink.cmp'

---@param p table palette
---@return table<string, vim.api.keyset.highlight>
function M.get(p)
  return {
    BlinkCmpMenu = { fg = p.fg, bg = p.bg_float },
    BlinkCmpMenuBorder = { fg = p.border, bg = p.bg_float },
    BlinkCmpMenuSelection = { bg = p.bg_select },
    BlinkCmpScrollBarThumb = { bg = p.scrollbar },
    BlinkCmpScrollBarGutter = { bg = p.bg_float },

    BlinkCmpLabel = { fg = p.fg },
    BlinkCmpLabelDeprecated = { fg = p.comment, strikethrough = true },
    BlinkCmpLabelMatch = { fg = p.blue },
    BlinkCmpLabelDetail = { fg = p.comment },
    BlinkCmpLabelDescription = { fg = p.comment },
    BlinkCmpSource = { fg = p.comment },
    BlinkCmpGhostText = { fg = p.comment },

    BlinkCmpDoc = { fg = p.fg, bg = p.bg_float },
    BlinkCmpDocBorder = { fg = p.border, bg = p.bg_float },
    BlinkCmpDocSeparator = { fg = p.border, bg = p.bg_float },
    BlinkCmpDocCursorLine = { bg = p.bg_line },
    BlinkCmpSignatureHelp = { fg = p.fg, bg = p.bg_float },
    BlinkCmpSignatureHelpBorder = { fg = p.border, bg = p.bg_float },
    BlinkCmpSignatureHelpActiveParameter = { bg = p.word_highlight },

    BlinkCmpKind = { fg = p.fg },
    BlinkCmpKindText = { fg = p.fg },
    BlinkCmpKindMethod = { fg = p.blue },
    BlinkCmpKindFunction = { fg = p.blue },
    BlinkCmpKindConstructor = { fg = p.blue },
    BlinkCmpKindField = { fg = p.red },
    BlinkCmpKindVariable = { fg = p.red },
    BlinkCmpKindProperty = { fg = p.red },
    BlinkCmpKindClass = { fg = p.yellow },
    BlinkCmpKindInterface = { fg = p.yellow },
    BlinkCmpKindStruct = { fg = p.yellow },
    BlinkCmpKindModule = { fg = p.yellow },
    BlinkCmpKindTypeParameter = { fg = p.yellow },
    BlinkCmpKindUnit = { fg = p.orange },
    BlinkCmpKindValue = { fg = p.orange },
    BlinkCmpKindConstant = { fg = p.orange },
    BlinkCmpKindEnum = { fg = p.yellow },
    BlinkCmpKindEnumMember = { fg = p.cyan },
    BlinkCmpKindKeyword = { fg = p.purple },
    BlinkCmpKindOperator = { fg = p.cyan },
    BlinkCmpKindSnippet = { fg = p.green },
    BlinkCmpKindColor = { fg = p.orange },
    BlinkCmpKindFile = { fg = p.fg },
    BlinkCmpKindFolder = { fg = p.blue },
    BlinkCmpKindReference = { fg = p.fg },
    BlinkCmpKindEvent = { fg = p.red },
  }
end

return M
```

- [ ] **Step 5: Write gitsigns.lua**

`lua/custom/plugins/colorscheme/groups/gitsigns.lua`:

```lua
-- gitsigns.nvim. Signs use the VSCode editorGutter colors.
local M = {}

M.detect = 'gitsigns'

---@param p table palette
---@return table<string, vim.api.keyset.highlight>
function M.get(p)
  return {
    GitSignsAdd = { fg = p.git_add },
    GitSignsChange = { fg = p.git_change },
    GitSignsDelete = { fg = p.git_delete },
    GitSignsChangedelete = { fg = p.git_change },
    GitSignsTopdelete = { fg = p.git_delete },
    GitSignsUntracked = { fg = p.git_add },

    GitSignsAddNr = { fg = p.git_add },
    GitSignsChangeNr = { fg = p.git_change },
    GitSignsDeleteNr = { fg = p.git_delete },
    GitSignsAddLn = { bg = p.diff_add_bg },
    GitSignsChangeLn = { bg = p.diff_change_bg },
    GitSignsDeleteLn = { bg = p.diff_delete_bg },

    GitSignsStagedAdd = { fg = p.git_add },
    GitSignsStagedChange = { fg = p.git_change },
    GitSignsStagedDelete = { fg = p.git_delete },
    GitSignsStagedChangedelete = { fg = p.git_change },
    GitSignsStagedTopdelete = { fg = p.git_delete },

    GitSignsAddInline = { bg = p.diff_add_bg },
    GitSignsChangeInline = { bg = p.diff_text_bg },
    GitSignsDeleteInline = { bg = p.diff_delete_bg },
    GitSignsAddPreview = { bg = p.diff_add_bg },
    GitSignsDeletePreview = { bg = p.diff_delete_bg },
    GitSignsCurrentLineBlame = { fg = p.comment },
  }
end

return M
```

- [ ] **Step 6: Write which_key.lua**

`lua/custom/plugins/colorscheme/groups/which_key.lua`:

```lua
-- which-key.nvim
local M = {}

M.detect = 'which-key'

---@param p table palette
---@return table<string, vim.api.keyset.highlight>
function M.get(p)
  return {
    WhichKey = { fg = p.blue },
    WhichKeyGroup = { fg = p.purple },
    WhichKeyDesc = { fg = p.fg },
    WhichKeySeparator = { fg = p.comment },
    WhichKeyIcon = { fg = p.cyan },
    WhichKeyValue = { fg = p.comment },
    WhichKeyNormal = { fg = p.fg, bg = p.bg_float },
    WhichKeyBorder = { fg = p.border, bg = p.bg_float },
    WhichKeyTitle = { fg = p.blue, bg = p.bg_float },
  }
end

return M
```

- [ ] **Step 7: Write todo_comments.lua**

`lua/custom/plugins/colorscheme/groups/todo_comments.lua`:

```lua
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
```

- [ ] **Step 8: Write mini.lua**

`lua/custom/plugins/colorscheme/groups/mini.lua`:

```lua
-- mini.nvim modules used by this config: statusline, icons, ai, surround.
local M = {}

M.detect = { 'mini.statusline', 'mini.icons', 'mini.ai', 'mini.surround' }

---@param p table palette
---@return table<string, vim.api.keyset.highlight>
function M.get(p)
  return {
    -- statusline: mode block in a syntax color on the list selection background
    MiniStatuslineModeNormal = { fg = p.blue, bg = p.bg_select },
    MiniStatuslineModeInsert = { fg = p.green, bg = p.bg_select },
    MiniStatuslineModeVisual = { fg = p.purple, bg = p.bg_select },
    MiniStatuslineModeReplace = { fg = p.red, bg = p.bg_select },
    MiniStatuslineModeCommand = { fg = p.orange, bg = p.bg_select },
    MiniStatuslineModeOther = { fg = p.cyan, bg = p.bg_select },
    MiniStatuslineDevinfo = { fg = p.status_fg, bg = p.bg_tab },
    MiniStatuslineFilename = { fg = p.status_fg, bg = p.bg },
    MiniStatuslineFileinfo = { fg = p.status_fg, bg = p.bg_tab },
    MiniStatuslineInactive = { fg = p.inactive_fg, bg = p.bg },

    -- icons
    MiniIconsAzure = { fg = p.blue },
    MiniIconsBlue = { fg = p.blue },
    MiniIconsCyan = { fg = p.cyan },
    MiniIconsGreen = { fg = p.green },
    MiniIconsGrey = { fg = p.comment },
    MiniIconsOrange = { fg = p.orange },
    MiniIconsPurple = { fg = p.purple },
    MiniIconsRed = { fg = p.red },
    MiniIconsYellow = { fg = p.yellow },

    -- surround flash
    MiniSurround = { bg = p.search },

    -- cursorword (editor.wordHighlightBackground), in case the module is turned on
    MiniCursorword = { bg = p.word_highlight },
    MiniCursorwordCurrent = { bg = p.word_highlight },
  }
end

return M
```

- [ ] **Step 9: Run the tests**

Run: `nvim --clean -l lua/custom/plugins/colorscheme/tests/run.lua 2>&1 | grep FAIL`
Expected: only failures for `fidget`, `mason`, `indent_blankline`, `neo_tree`, `dap` (module not found) and the detect test. Task 6 fixes them.

- [ ] **Step 10: Check the real config**

Run:

```bash
nvim --headless "+lua vim.schedule(function() print(vim.api.nvim_get_hl(0, { name = 'GitSignsAdd' }).fg ~= nil, vim.api.nvim_get_hl(0, { name = 'BlinkCmpMenu' }).bg ~= nil, vim.api.nvim_get_hl(0, { name = 'MiniStatuslineModeNormal' }).bg ~= nil) vim.cmd 'qa!' end)" 2>&1 | tail -2
```

Expected: `true true true`, no error lines.

- [ ] **Step 11: Check formatting, then commit**

Run: `~/.local/share/nvim/mason/bin/stylua --check lua/custom/plugins/colorscheme`
Expected: no output.

```bash
git add lua/custom/plugins/colorscheme
git commit -m "Add One Dark groups for telescope, blink, gitsigns, which-key, todo-comments and mini

Written-by: Claude"
```

---

### Task 6: Integrations: fidget, mason, indent-blankline, neo-tree, dap

**Files:**
- Create: `lua/custom/plugins/colorscheme/groups/fidget.lua`
- Create: `lua/custom/plugins/colorscheme/groups/mason.lua`
- Create: `lua/custom/plugins/colorscheme/groups/indent_blankline.lua`
- Create: `lua/custom/plugins/colorscheme/groups/neo_tree.lua`
- Create: `lua/custom/plugins/colorscheme/groups/dap.lua`

**Interfaces:**
- Consumes: palette keys, `integrations_spec.lua` from Task 5.
- Produces: the last five integration files, each with `detect` and `get(p)`.

- [ ] **Step 1: Confirm the tests fail for these five files**

Run: `nvim --clean -l lua/custom/plugins/colorscheme/tests/run.lua 2>&1 | grep FAIL`
Expected: failures for `fidget`, `mason`, `indent_blankline`, `neo_tree`, `dap` and the detect test.

- [ ] **Step 2: Write fidget.lua**

`lua/custom/plugins/colorscheme/groups/fidget.lua`:

```lua
-- fidget.nvim: LSP progress messages in the corner.
local M = {}

M.detect = 'fidget'

---@param p table palette
---@return table<string, vim.api.keyset.highlight>
function M.get(p)
  return {
    FidgetTitle = { fg = p.fg },
    FidgetTask = { fg = p.comment },
    FidgetNormal = { fg = p.comment, bg = p.none },
  }
end

return M
```

- [ ] **Step 3: Write mason.lua**

`lua/custom/plugins/colorscheme/groups/mason.lua`:

```lua
-- mason.nvim window.
local M = {}

M.detect = 'mason'

---@param p table palette
---@return table<string, vim.api.keyset.highlight>
function M.get(p)
  return {
    MasonNormal = { fg = p.fg, bg = p.bg_float },
    MasonHeader = { fg = p.bg, bg = p.blue },
    MasonHeaderSecondary = { fg = p.bg, bg = p.orange },
    MasonHeading = { fg = p.blue },
    MasonHighlight = { fg = p.green },
    MasonHighlightBlock = { fg = p.bg, bg = p.green },
    MasonHighlightBlockBold = { fg = p.bg, bg = p.green },
    MasonHighlightSecondary = { fg = p.orange },
    MasonHighlightBlockSecondary = { fg = p.bg, bg = p.orange },
    MasonHighlightBlockBoldSecondary = { fg = p.bg, bg = p.orange },
    MasonLink = { fg = p.blue, underline = true },
    MasonMuted = { fg = p.comment },
    MasonMutedBlock = { fg = p.comment, bg = p.bg_select },
    MasonMutedBlockBold = { fg = p.fg, bg = p.bg_select },
    MasonError = { fg = p.diag_error },
    MasonWarning = { fg = p.diag_warn },
  }
end

return M
```

- [ ] **Step 4: Write indent_blankline.lua**

`lua/custom/plugins/colorscheme/groups/indent_blankline.lua`:

```lua
-- indent-blankline.nvim (module name ibl). Guides use editorIndentGuide colors.
local M = {}

M.detect = 'ibl'

---@param p table palette
---@return table<string, vim.api.keyset.highlight>
function M.get(p)
  return {
    IblIndent = { fg = p.guide },
    IblWhitespace = { fg = p.whitespace },
    IblScope = { fg = p.indent_active },
  }
end

return M
```

- [ ] **Step 5: Write neo_tree.lua**

`lua/custom/plugins/colorscheme/groups/neo_tree.lua`:

```lua
-- neo-tree.nvim. Mirrors the VSCode side bar: same background as the editor, sideBar.border.
local M = {}

M.detect = 'neo-tree'

---@param p table palette
---@return table<string, vim.api.keyset.highlight>
function M.get(p)
  return {
    NeoTreeNormal = { fg = p.fg, bg = p.bg },
    NeoTreeNormalNC = { fg = p.fg, bg = p.bg },
    NeoTreeEndOfBuffer = { fg = p.bg, bg = p.bg },
    NeoTreeWinSeparator = { fg = p.border_sidebar, bg = p.bg },
    NeoTreeVertSplit = { fg = p.border_sidebar, bg = p.bg },
    NeoTreeCursorLine = { bg = p.bg_select },
    NeoTreeStatusLine = { fg = p.status_fg, bg = p.bg },
    NeoTreeStatusLineNC = { fg = p.inactive_fg, bg = p.bg },
    NeoTreeSignColumn = { bg = p.bg },

    NeoTreeRootName = { fg = p.fg },
    NeoTreeDirectoryName = { fg = p.fg },
    NeoTreeDirectoryIcon = { fg = p.blue },
    NeoTreeFileName = { fg = p.fg },
    NeoTreeFileNameOpened = { fg = p.list_fg },
    NeoTreeFileIcon = { fg = p.fg },
    NeoTreeSymbolicLinkTarget = { fg = p.cyan },
    NeoTreeIndentMarker = { fg = p.whitespace },
    NeoTreeExpander = { fg = p.comment },
    NeoTreeDotfile = { fg = p.comment },
    NeoTreeHiddenByName = { fg = p.comment },
    NeoTreeMessage = { fg = p.comment },
    NeoTreeModified = { fg = p.orange },
    NeoTreeDimText = { fg = p.comment },

    -- gitDecoration colors
    NeoTreeGitAdded = { fg = p.green },
    NeoTreeGitModified = { fg = p.yellow },
    NeoTreeGitDeleted = { fg = p.red },
    NeoTreeGitRenamed = { fg = p.yellow },
    NeoTreeGitUntracked = { fg = p.green },
    NeoTreeGitIgnored = { fg = p.comment },
    NeoTreeGitConflict = { fg = p.red },
    NeoTreeGitStaged = { fg = p.green },
    NeoTreeGitUnstaged = { fg = p.yellow },

    NeoTreeTitleBar = { fg = p.fg, bg = p.bg_tab },
    NeoTreeFloatBorder = { fg = p.border, bg = p.bg_float },
    NeoTreeFloatTitle = { fg = p.blue, bg = p.bg_float },
    NeoTreeFloatNormal = { fg = p.fg, bg = p.bg_float },
    NeoTreeTabActive = { fg = p.tab_fg, bg = p.bg_tab },
    NeoTreeTabInactive = { fg = p.inactive_fg, bg = p.bg },
    NeoTreeTabSeparatorActive = { fg = p.bg_tab, bg = p.bg_tab },
    NeoTreeTabSeparatorInactive = { fg = p.bg, bg = p.bg },
  }
end

return M
```

- [ ] **Step 6: Write dap.lua**

`lua/custom/plugins/colorscheme/groups/dap.lua`:

```lua
-- nvim-dap and nvim-dap-ui. The debug plugin is off by default in this config,
-- so these groups are applied only when it is turned on.
local M = {}

M.detect = { 'dap', 'dapui' }

---@param p table palette
---@return table<string, vim.api.keyset.highlight>
function M.get(p)
  return {
    DapBreakpoint = { fg = p.red },
    DapBreakpointCondition = { fg = p.orange },
    DapBreakpointRejected = { fg = p.comment },
    DapLogPoint = { fg = p.orange },
    DapStopped = { fg = p.green },
    DapStoppedLine = { bg = p.bg_line },

    DapUIScope = { fg = p.blue },
    DapUIType = { fg = p.yellow },
    DapUIValue = { fg = p.fg },
    DapUIModifiedValue = { fg = p.orange },
    DapUIDecoration = { fg = p.blue },
    DapUIThread = { fg = p.green },
    DapUIStoppedThread = { fg = p.blue },
    DapUIFrameName = { fg = p.fg },
    DapUISource = { fg = p.purple },
    DapUILineNumber = { fg = p.line_nr },
    DapUIFloatBorder = { fg = p.border, bg = p.bg_float },
    DapUIWatchesEmpty = { fg = p.comment },
    DapUIWatchesValue = { fg = p.green },
    DapUIWatchesError = { fg = p.diag_error },
    DapUIBreakpointsPath = { fg = p.blue },
    DapUIBreakpointsInfo = { fg = p.green },
    DapUIBreakpointsCurrentLine = { fg = p.green },
    DapUIBreakpointsLine = { fg = p.line_nr },
    DapUIBreakpointsDisabledLine = { fg = p.comment },
    DapUICurrentFrameName = { fg = p.green },
    DapUIStepOver = { fg = p.blue },
    DapUIStepInto = { fg = p.blue },
    DapUIStepBack = { fg = p.blue },
    DapUIStepOut = { fg = p.blue },
    DapUIStop = { fg = p.red },
    DapUIPlayPause = { fg = p.green },
    DapUIRestart = { fg = p.green },
    DapUIUnavailable = { fg = p.comment },
    DapUIWinSelect = { fg = p.blue },
    DapUIEndofBuffer = { fg = p.bg },
  }
end

return M
```

- [ ] **Step 7: Run the whole test suite**

Run: `nvim --clean -l lua/custom/plugins/colorscheme/tests/run.lua`
Expected: `37 passed, 0 failed`

- [ ] **Step 8: Check the real config once more**

Run:

```bash
nvim --headless "+lua vim.schedule(function() print(vim.api.nvim_get_hl(0, { name = 'NeoTreeNormal' }).bg ~= nil, vim.api.nvim_get_hl(0, { name = 'IblScope' }).fg ~= nil, vim.api.nvim_get_hl(0, { name = 'MasonHeader' }).bg ~= nil) vim.cmd 'qa!' end)" 2>&1 | tail -2
```

Expected: `true true true`, no error lines.

- [ ] **Step 9: Check formatting, then commit**

Run: `~/.local/share/nvim/mason/bin/stylua --check lua/custom/plugins/colorscheme`
Expected: no output.

```bash
git add lua/custom/plugins/colorscheme
git commit -m "Add One Dark groups for fidget, mason, indent-blankline, neo-tree and dap

Written-by: Claude"
```

---

### Task 7: Visual verification against VSCode

This task needs the user. It compares screenshots and fixes the mapping. Do not skip it: it settles the two open items in the spec (Lua operators, TypeScript parameters) and the CSS capture names.

**Files:**
- Create: sample files in the scratchpad directory (not committed): `samples/sample.lua`, `sample.ts`, `sample.js`, `sample.html`, `sample.css`, `sample.md`, `sample.json`
- Modify: `lua/custom/plugins/colorscheme/groups/treesitter.lua` and `lsp.lua` as the comparison requires
- Modify: `docs/superpowers/specs/2026-10-09-onedark-colorscheme-design.md` (record the answers to the open items)

- [ ] **Step 1: Write the sample files**

Each file must contain every token kind from the spec tables for its language. Minimum content:

`sample.lua`:

```lua
-- A comment with a TODO: marker
local M = {}
local count = 0
local name = 'one \n dark'
local ok, err = pcall(require, 'module')
M.items = { 1, 2.5, true, nil }

---@param a number
function M.add(a, b)
  if a > b and not (a == b) then return a + b * 2 end
  for i = 1, #M.items do
    count = count + i
  end
  return string.format('%d', count), vim.fn.expand '%'
end

M.add(1, 2)
print(M.items[1], self)
return M
```

`sample.ts`:

```ts
import { readFile } from 'node:fs'
// comment
const LIMIT = 10
let total: number = 0
enum Color { Red, Green }
interface Item { id: number; name?: string }
class Box<T> extends Base implements Item {
  private items: T[] = []
  constructor(public id: number, readonly name: string) { super() }
  add(item: T): this { this.items.push(item); return this }
}
function sum(a: number, b = 2): number {
  const re = /ab+c/gi
  return typeof a === 'number' && a !== b ? a + b : Math.max(a, b) ?? 0
}
export default async function main(): Promise<void> {
  const box = new Box<string>(1, 'x')
  console.log(`total: ${total}`, sum(LIMIT, 3), Color.Red, box.name)
  for (const item of [1, 2]) total += item
}
```

`sample.js`: the same as `sample.ts` without types and the enum or interface.

`sample.html`:

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <!-- comment -->
    <meta charset="utf-8" />
    <title>One Dark &amp; Night</title>
    <style>
      body { color: #abb2bf; }
    </style>
  </head>
  <body class="main" id="app" data-count="3">
    <a href="https://example.com">Link</a>
    <script>const x = 1;</script>
  </body>
</html>
```

`sample.css`:

```css
/* comment */
@import url('base.css');
:root { --gap: 8px; }
div.btn#app:hover::before, a[href] {
  display: flex !important;
  color: red;
  background: #16191d;
  margin: 10px 0.5em 50%;
  width: calc(100% - var(--gap));
}
@media (max-width: 600px) { .btn { display: none; } }
```

`sample.md`:

````markdown
# Heading 1
## Heading 2
Text with **bold**, *italic*, `code`, and a [link](https://example.com).
- list item
1. numbered
> quote
```lua
local x = 1
```
````

`sample.json`:

```json
{ "name": "one", "count": 3, "ok": true, "none": null, "list": [1, "two"] }
```

- [ ] **Step 2: Ask the user to open the files in VSCode and send screenshots**

Message to the user: "The sample files are in `<scratchpad>/samples/`. Please open each one in VSCode with One Dark Pro Night Flat (and semantic highlighting on, which is the default) and send a screenshot of each. I compare them with Neovim."

- [ ] **Step 3: Open each file in Neovim and record the capture under each token**

For each sample, run `nvim <file>` in a terminal and take a screenshot. For any token whose color differs from VSCode, put the cursor on it and run `:Inspect`. It prints the tree-sitter captures and the LSP token groups, with the one that wins last.

- [ ] **Step 4: Fix the mapping**

For each difference, change the capture or token group in `treesitter.lua` or `lsp.lua` to the VSCode color. Typical cases:

- A capture name in the CSS block is wrong: rename it to what `:Inspect` printed.
- Lua operators are plain in VSCode: add `['@operator.lua'] = { fg = p.fg }`.
- TypeScript parameters are plain in VSCode: set `['@variable.parameter'] = { fg = p.fg }` and `['@lsp.type.parameter'] = { fg = p.fg }`.

Keep the "no hex literal outside palette.lua" rule.

- [ ] **Step 5: Run the tests**

Run: `nvim --clean -l lua/custom/plugins/colorscheme/tests/run.lua`
Expected: `37 passed, 0 failed`. If a test in `groups_spec.lua` now contradicts a confirmed VSCode color, update the expected value in the test, with a comment that names the screenshot check.

- [ ] **Step 6: Record the answers in the spec**

In `docs/superpowers/specs/2026-10-09-onedark-colorscheme-design.md`, replace the section "Open items for the screenshot check" with a short "Screenshot check results" section that states the final color for Lua operators and TypeScript parameters, and the confirmed CSS capture names.

- [ ] **Step 7: Check formatting, then commit**

Run: `~/.local/share/nvim/mason/bin/stylua --check lua/custom/plugins/colorscheme`
Expected: no output.

```bash
git add lua/custom/plugins/colorscheme docs/superpowers/specs/2026-10-09-onedark-colorscheme-design.md
git commit -m "Match the One Dark mapping to VSCode screenshots

Written-by: Claude"
```

- [ ] **Step 8: Open a pull request**

```bash
git push -u origin onedark-colorscheme
gh pr create --title "Switch the colorscheme to One Dark Pro Night Flat" --body "$(cat <<'EOF'
## Summary

- Move apple.nvim out of this repo (it gets its own repository).
- Add a standalone One Dark Pro Night Flat colorscheme in `lua/custom/plugins/colorscheme/`, built from the VSCode theme JSON.
- Same plugin integrations as before: telescope, blink, gitsigns, which-key, todo-comments, mini, fidget, mason, indent-blankline, neo-tree, dap.
- Headless tests with a CI workflow.

Spec: `docs/superpowers/specs/2026-10-09-onedark-colorscheme-design.md`

## Test plan

- [ ] `nvim --clean -l lua/custom/plugins/colorscheme/tests/run.lua` passes
- [ ] Screenshots match VSCode for Lua, TypeScript, JavaScript, HTML, CSS, Markdown and JSON
EOF
)"
```
