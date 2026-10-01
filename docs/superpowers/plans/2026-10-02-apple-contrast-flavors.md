# Apple Themes: Two Flavors With a Contrast Rule Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Go back to two `apple` flavors (dark and light) with the colors from `main`, add a stricter contrast rule to the tests, and keep the removal of the minimal Neovim config in `macos-configs`.

**Architecture:** The first version of this plan built four flavors and a `contrast` option; that work is already committed on the `apple-contrast-flavors` branches. This revision takes the theme code and theme files back from `main` and keeps only what is still wanted: the cleanup in `macos-configs`, better theme tests, and a stricter contrast check.

**Tech Stack:** Lua, Neovim 0.11+ (`nvim --clean -l` as the test runner), StyLua, Ghostty theme files, Warp YAML themes.

**Spec:** `docs/superpowers/specs/2026-10-02-apple-contrast-flavors-design.md` (in `neovim-config`)

## Global Constraints

- Two repositories, each on its existing branch `apple-contrast-flavors`: `/Users/sergii/github/personal/neovim-config` and `/Users/sergii/github/personal/macos-configs`.
- Theme colors must be byte-for-byte the files from `main`. Take them with `git checkout main -- <path>`, never retype them.
- Contrast rule (WCAG ratio against `bg`): syntax text colors at least 4.5 in dark and 4.0 in light; normal text at least 7.0; comments at least 3.0; text on search and selection backgrounds at least 4.5.
- No `contrast` option, no `-contrast` / `_contrast` theme files.
- `neovim-config` Lua must pass `stylua --check .`.
- `macos-configs` has uncommitted user changes (`ghostty/.config/ghostty/config`, `git/.gitconfig`, `herdr/`, `oh-my-posh/`, `zsh/`, `lazygit/`). Never edit, stage or commit them. Stage files by exact path only.
- Git commits: the message may end with exactly one trailer line, `Written by Claude`. No email address, no session link.
- Do not push and do not open pull requests without asking the user.

## Review Focus

1. A color in `palette.lua` is changed to a weak one later (for example Apple's default yellow in light): the palette test fails and names the color. Pinned in Task 1.
2. A user still has `contrast = 'increased'` in `setup()`: the colorscheme loads without an error and ignores the key. Pinned in Task 1.
3. A theme file is incomplete (a missing ANSI slot, a missing `cursor-color`, a Warp file without `accent`): the test names the file and the key. Pinned in Task 2.
4. A `-contrast` theme file is left behind: Ghostty would still list it. Checked in Task 2.

---

### Task 1: apple.nvim back to two flavors, stricter contrast test

**Files (repository `neovim-config`):**
- Restore from `main`: `apple.nvim/lua/apple/palette.lua`, `apple.nvim/lua/apple/config.lua`, `apple.nvim/lua/apple/init.lua`, `apple.nvim/tests/helpers.lua`, `apple.nvim/tests/palette_spec.lua`, `apple.nvim/tests/config_spec.lua`, `apple.nvim/tests/colorscheme_spec.lua`, `apple.nvim/tests/integrations_spec.lua`, `apple.nvim/README.md`, `init.lua`
- Modify: `apple.nvim/tests/palette_spec.lua` (contrast limits), `apple.nvim/tests/colorscheme_spec.lua` (one new test), `apple.nvim/README.md` (one note)

- [ ] **Step 1: Restore the files from `main`**

```bash
cd /Users/sergii/github/personal/neovim-config
git checkout main -- apple.nvim/lua apple.nvim/tests apple.nvim/README.md init.lua
nvim --clean -l apple.nvim/tests/run.lua | tail -1
```

Expected: the same result as on `main`, `N passed, 0 failed`.

- [ ] **Step 2: Make the contrast test stricter**

In `apple.nvim/tests/palette_spec.lua`, in the test `mode .. ': text is readable'`, replace:

```lua
    for _, name in ipairs { 'red', 'orange', 'yellow', 'green', 'teal', 'blue', 'purple', 'pink' } do
      t.min_contrast(p[name], p.bg, 3.0, name .. ' on bg')
    end
```

with:

```lua
    -- Syntax colors: 4.5 in dark. Light reaches 4.0 on this background;
    -- 4.5 would need a white background.
    local min = mode == 'dark' and 4.5 or 4.0
    for _, name in ipairs { 'red', 'orange', 'yellow', 'green', 'teal', 'blue', 'purple', 'pink' } do
      t.min_contrast(p[name], p.bg, min, name .. ' on bg')
    end
```

- [ ] **Step 3: Check that the stricter test can fail**

Temporarily change `yellow = '#A16A00'` to `yellow = '#FFCC00'` in the light palette of `apple.nvim/lua/apple/palette.lua`, run the tests, and undo the change:

```bash
nvim --clean -l apple.nvim/tests/run.lua | grep -A1 '^FAIL'
git checkout main -- apple.nvim/lua/apple/palette.lua
```

Expected: `FAIL light: text is readable` with `yellow on bg: #FFCC00 on #F2F2F7 has 1.35:1, needs 4.0:1`. (The test that compares text colors with Apple's increased contrast values fails too.)

- [ ] **Step 4: Pin that an old `contrast` key is harmless**

Append to `apple.nvim/tests/colorscheme_spec.lua`:

```lua

-- The contrast option was removed. An old config that still sets it must load.
t.test('an unknown option such as contrast is ignored', function()
  require('apple').setup { contrast = 'increased' }
  vim.o.background = 'dark'
  local ok, err = pcall(vim.cmd.colorscheme, 'apple')
  t.ok(ok, tostring(err))
  t.eq(palette.dark.bg, t.hex(hl('Normal').bg))
  config.extend()
end)
```

- [ ] **Step 5: Add the README note**

In `apple.nvim/README.md`, after the palette table and before `## Development`, add:

```markdown
Text colors are Apple's increased contrast colors; backgrounds and grays are
Apple's default ones. The tests keep every syntax color at a contrast of at
least 4.5 against the background in dark and 4.0 in light.

```

- [ ] **Step 6: Format, run the tests, compare with `main`**

```bash
stylua apple.nvim && stylua --check . && nvim --clean -l apple.nvim/tests/run.lua | tail -1
git diff --stat main -- apple.nvim init.lua
```

Expected: `N passed, 0 failed`. The diff against `main` lists only `apple.nvim/README.md`, `apple.nvim/tests/palette_spec.lua` and `apple.nvim/tests/colorscheme_spec.lua`.

- [ ] **Step 7: Commit**

```bash
git add apple.nvim init.lua
git commit -m "Go back to two apple flavors and make the contrast test stricter

Written by Claude"
```

### Task 2: Ghostty and Warp back to two flavors

**Files (repository `macos-configs`):**
- Restore from `main`: `ghostty/.config/ghostty/themes/apple-dark`, `ghostty/.config/ghostty/themes/apple-light`, `warp/.warp/themes/apple_dark.yaml`, `warp/.warp/themes/apple_light.yaml`
- Delete: `ghostty/.config/ghostty/themes/apple-dark-contrast`, `ghostty/.config/ghostty/themes/apple-light-contrast`, `warp/.warp/themes/apple_dark_contrast.yaml`, `warp/.warp/themes/apple_light_contrast.yaml`
- Modify: `tests/themes/themes_spec.lua`, `README.md`

- [ ] **Step 1: Change the test to two flavors with the old color mapping**

In `tests/themes/themes_spec.lua`:

Replace the `flavors` table and its comment with:

```lua
local flavors = {
  { ghostty = 'apple-dark', warp = 'apple_dark.yaml', mode = 'dark' },
  { ghostty = 'apple-light', warp = 'apple_light.yaml', mode = 'light' },
}
```

Replace the comment above `black_white` with `-- ANSI slots 0, 7, 8 and 15 (black and white).`

Replace `local mode, column = f.mode, f.column` with `local mode = f.mode`.

Replace the test `normal colors follow the flavor, bright colors are increased contrast` with:

```lua
  t.test(f.ghostty .. ': normal colors are increased contrast, bright colors are default', function()
    local theme = ghostty()
    for name, slot in pairs(slots) do
      t.eq(hig[name][hc], theme.palette[slot], name .. ' (slot ' .. slot .. ')')
      t.eq(hig[name][mode], theme.palette[slot + 8], name .. ' (slot ' .. (slot + 8) .. ')')
    end
  end)
```

Replace the test `background and cursor are the HIG colors of the flavor` with:

```lua
  t.test(f.ghostty .. ': background is HIG gray 6, cursor is HIG indigo', function()
    local theme = ghostty()
    t.eq(hig.gray6[mode], theme['background'], 'background')
    t.eq(hig.indigo[mode], theme['cursor-color'], 'cursor-color')
  end)
```

Rename the test `foreground, cursor text and selection do not follow the contrast` to `foreground, cursor text and selection`.

- [ ] **Step 2: Run the tests to see them fail**

Run: `nvim --clean -l tests/themes/run.lua | grep -A1 '^FAIL'`

Expected: `FAIL apple-dark: normal colors are increased contrast, bright colors are default` and the same for `apple-light`.

- [ ] **Step 3: Restore the theme files and delete the contrast files**

```bash
git checkout main -- ghostty/.config/ghostty/themes/apple-dark ghostty/.config/ghostty/themes/apple-light warp/.warp/themes/apple_dark.yaml warp/.warp/themes/apple_light.yaml
git rm -q ghostty/.config/ghostty/themes/apple-dark-contrast ghostty/.config/ghostty/themes/apple-light-contrast warp/.warp/themes/apple_dark_contrast.yaml warp/.warp/themes/apple_light_contrast.yaml
```

- [ ] **Step 4: Remove the flavors part from the README**

In `README.md`, in the `## APPLE THEMES` section, delete everything from the line `There are four flavors.` up to (not including) the line `> [!NOTE]`.

- [ ] **Step 5: Run the tests and check for leftovers**

```bash
nvim --clean -l tests/themes/run.lua | tail -1
git diff --stat main -- ghostty warp
ls ghostty/.config/ghostty/themes warp/.warp/themes
grep -n -i 'contrast' README.md
```

Expected: `14 passed, 0 failed` (7 tests for each of the 2 flavors). The diff against `main` for `ghostty` and `warp` is empty. Each themes folder holds only the two apple files. `grep` prints nothing.

- [ ] **Step 6: Commit**

```bash
git add tests/themes/themes_spec.lua README.md
git commit -m "Go back to two Apple flavors for Ghostty and Warp

Written by Claude"
git show --stat HEAD
```

Expected: the commit lists the restored theme files, the four deleted files, `tests/themes/themes_spec.lua` and `README.md`. None of the user's uncommitted files are in it.

---

## After both tasks

- Ask the user to look at the result in a new Ghostty window (dark and light) and in Neovim.
- Use superpowers:finishing-a-development-branch for each repository. Pushing and opening pull requests needs the user's OK.
