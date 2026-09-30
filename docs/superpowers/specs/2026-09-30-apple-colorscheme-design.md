# apple.nvim colorscheme design

Date: 2026-09-30

## Goal

Replace Catppuccin in this Neovim config with a custom `apple` colorscheme
built on Apple Human Interface Guidelines (HIG) system colors. The theme is
built as a self-contained Neovim plugin so it can move to its own repository
later without rework.

Two earlier versions exist in `macos-configs` and `nvim-kickstart`. They share
one palette and about 90 highlight groups, have no options and no plugin
integrations. This version keeps the palette and adds structure, options,
integrations and tests.

Examples we follow: [tokyonight.nvim](https://github.com/folke/tokyonight.nvim)
for module layout and [catppuccin/nvim](https://github.com/catppuccin/nvim) for
auto-detected integrations.

## Requirements

- Two flavors: `dark` and `light`, using the existing Apple palette values.
- The flavor follows `vim.o.background` by default. Ghostty sets it from the
  macOS appearance, and Neovim reloads the colorscheme when it changes.
- Integrations for the plugins used in this config are auto-detected.
- Small option surface: flavor, styles, integrations, `on_highlights`.
- Self-contained plugin folder inside this repo, tests included, CI runs them.

## Out of scope

- Increased-contrast flavors.
- Terminal theme generation (Ghostty, Warp). Those live in `macos-configs`.
- Transparent background option.
- Compile cache for highlight groups.

## File layout

```
apple.nvim/
  colors/apple.lua              -- entry for :colorscheme apple
  lua/apple/init.lua            -- setup(), load()
  lua/apple/config.lua          -- defaults, stored options, extend()
  lua/apple/palette.lua         -- M.dark, M.light
  lua/apple/util.lua            -- mix(), has_plugin(), apply()
  lua/apple/groups/init.lua     -- core list, integration list, merge
  lua/apple/groups/editor.lua
  lua/apple/groups/syntax.lua
  lua/apple/groups/treesitter.lua
  lua/apple/groups/lsp.lua
  lua/apple/groups/telescope.lua
  lua/apple/groups/blink.lua
  lua/apple/groups/gitsigns.lua
  lua/apple/groups/which_key.lua
  lua/apple/groups/todo_comments.lua
  lua/apple/groups/mini.lua
  lua/apple/groups/fidget.lua
  lua/apple/groups/mason.lua
  lua/apple/groups/indent_blankline.lua
  lua/apple/groups/neo_tree.lua
  lua/apple/groups/dap.lua
  tests/run.lua
  tests/helpers.lua
  tests/*_spec.lua
  README.md
  LICENSE
```

The folder is a complete plugin. Moving it later is
`git subtree split -P apple.nvim` into the new repository, then replacing the
`runtimepath` line in `init.lua` with `vim.pack.add`.

## Modules

### `colors/apple.lua`

One line: `require('apple').load()`.

### `lua/apple/init.lua`

- `M.setup(opts)`: stores options through `config.extend(opts)`. Does not
  apply any highlights.
- `M.load()`: the real work.
  1. Resolve the flavor (see Flavor below).
  2. `vim.cmd 'highlight clear'`, set `vim.g.colors_name = 'apple'`.
  3. `groups = require('apple.groups').get(palette, opts)`.
  4. Call `opts.on_highlights(groups, palette)` if set.
  5. `util.apply(groups)` and set `vim.g.terminal_color_0..15`.

### `lua/apple/config.lua`

```lua
M.defaults = {
  flavor = 'auto',            -- 'auto' | 'dark' | 'light'
  styles = {
    comments = {},            -- e.g. { italic = true }
    keywords = { bold = true },
    functions = {},
    strings = {},
  },
  integrations = {},          -- name -> true/false, overrides detection
  on_highlights = nil,        -- function(groups, palette)
}
M.options = deep copy of defaults
function M.extend(opts) -- vim.tbl_deep_extend('force', defaults, opts)
```

`setup` is optional. `:colorscheme apple` works with defaults.

### `lua/apple/palette.lua`

`M.dark` and `M.light` with the values from `macos-configs`, unchanged.
Additions:

- `none = 'NONE'`.
- Derived colors computed once with `util.mix` so group files stay pure:
  `diff_add_bg`, `diff_change_bg`, `diff_delete_bg` (15% over `bg`) and
  `diff_text_bg` (30% over `bg`).

Semantic names available to group files:
`bg, bg_alt, border, line_nr, comment, fg, cursor, selection, selection_fg,
search, cur_search, search_fg, red, orange, yellow, green, teal, blue, purple,
pink, diff_add, diff_change, diff_delete, diff_add_bg, diff_change_bg,
diff_delete_bg, diff_text_bg, none, terminal[1..16]`.

### `lua/apple/util.lua`

- `mix(fg, bg, amount)`: blend two `#RRGGBB` colors. Same as today.
- `has_plugin(names)`: true when any name is in `package.loaded`, or
  `vim.api.nvim_get_runtime_file('lua/<name>*', false)` finds a file, or a
  runtimepath directory ends with the plugin name. Takes a string or a list.
- `apply(groups)`: `nvim_set_hl(0, name, def)` for every entry.

### `lua/apple/groups/*.lua`

Every file returns `{ get = function(p, opts) return { Group = def } end }`
where `def` is a table for `nvim_set_hl`. Group files never call `vim.api`.

Integration files also return `detect`, a string or list of module names for
`util.has_plugin`. Core files have no `detect`.

`groups/init.lua`:

```lua
M.core = { 'editor', 'syntax', 'treesitter', 'lsp' }
M.integrations = { 'telescope', 'blink', 'gitsigns', 'which_key',
  'todo_comments', 'mini', 'fidget', 'mason', 'indent_blankline',
  'neo_tree', 'dap' }

function M.enabled(name, opts)
  local forced = opts.integrations[name]
  if forced ~= nil then return forced end
  return util.has_plugin(require('apple.groups.' .. name).detect)
end

function M.get(p, opts)
  -- merge core files, then every enabled integration, later wins
end
```

Detection table:

| integration      | detect                       |
|------------------|------------------------------|
| telescope        | `telescope`                  |
| blink            | `blink.cmp`                  |
| gitsigns         | `gitsigns`                   |
| which_key        | `which-key`                  |
| todo_comments    | `todo-comments`              |
| mini             | `mini` (any `mini.*` module) |
| fidget           | `fidget`                     |
| mason            | `mason`                      |
| indent_blankline | `ibl`                        |
| neo_tree         | `neo-tree`                   |
| dap              | `dap`, `dapui`               |

Groups only add highlights, so a false positive is harmless.

Styles: `syntax.lua` merges `opts.styles.comments` into `Comment`,
`opts.styles.keywords` into `Keyword`, `Statement` and the `@keyword.*`
captures, `opts.styles.functions` into `Function`, `opts.styles.strings` into
`String`. Merge is `vim.tbl_extend('force', { fg = ... }, style)`.

## Flavor and auto-switch

- `flavor = 'auto'`: palette is `palette[vim.o.background]`. The theme never
  sets `background` in this mode, so it keeps following the terminal. Neovim
  0.11+ re-runs `:colorscheme` when `background` changes, so no autocmd is
  needed.
- `flavor = 'dark' | 'light'`: `load()` sets `vim.o.background` to match
  before applying. A module-level guard flag stops the `OptionSet` -> reload ->
  set loop.

## Wiring into this config

Replace the Catppuccin block in `init.lua`:

```lua
-- [[ Colorscheme ]]
-- The "apple" colorscheme lives in apple.nvim/ (a plugin folder).
vim.opt.runtimepath:prepend(vim.fn.stdpath 'config' .. '/apple.nvim')
require('apple').setup { styles = { comments = {} } }
vim.cmd.colorscheme 'apple'
```

Remove `vim.pack.add { gh 'catppuccin/nvim' }` and the `nvim` entry in
`nvim-pack-lock.json`. Keep the comment that explains why `background` must not
be set by hand.

## Testing

`apple.nvim/tests/run.lua` prepends the plugin folder to the runtimepath, loads
`tests/helpers.lua` (the small `test/eq/ok/report` helper from `macos-configs`)
and runs every `tests/*_spec.lua`. Run with:

```
nvim --clean -l apple.nvim/tests/run.lua
```

Specs:

- `palette_spec`: every color is `#RRGGBB`; values match the HIG table
  (`tests/hig.lua` copied from `macos-configs`); derived diff colors equal
  `util.mix` results.
- `util_spec`: `mix` math; `has_plugin` true for a loaded module, false for a
  fake name.
- `colorscheme_spec`: for both flavors, `:colorscheme apple` loads,
  `colors_name` is `apple`, `Normal`, `Comment`, `Keyword`, `String`,
  `DiagnosticError` use the palette; terminal colors are set; `flavor = 'dark'`
  sets `background`; `styles.comments = { italic = true }` is applied;
  `on_highlights` overrides win.
- `integrations_spec`: every integration file has `detect` and `get` returns
  only valid highlight defs (known keys, hex or `NONE` colors) for both
  flavors; `integrations = { telescope = false }` removes `TelescopeNormal`;
  `integrations = { neo_tree = true }` adds `NeoTreeNormal` without the plugin.

CI: a new workflow `.github/workflows/apple-tests.yml` installs stable Neovim
(`rhysd/action-setup-vim`) and runs the command above. The existing stylua
workflow already covers the new folder.

## Migration later

1. `git subtree split -P apple.nvim -b apple-nvim` and push to the new repo.
2. In `init.lua`, replace the `runtimepath` line with
   `vim.pack.add { gh '<user>/apple.nvim' }`.
3. Delete `apple.nvim/` from this repo. The CI job moves with the folder.
