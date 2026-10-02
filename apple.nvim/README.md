# apple.nvim

A Neovim colorscheme built from Apple system colors
([Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/color)).
Two flavors, dark and light. The flavor follows `'background'`, so it switches
with your terminal and macOS appearance.

Syntax colors follow Xcode: pink keywords, red strings, yellow numbers, blue
functions, teal types, orange preprocessor.
Members and properties are mint, function parameters are brown, and delimiters
(dots and commas) are cyan.

## Requirements

- Neovim 0.11 or newer.
- A terminal that reports its theme (Ghostty, WezTerm, kitty, iTerm2, ...) if
  you want automatic switching.

## Install

With `vim.pack` (Neovim 0.12+):

```lua
vim.pack.add { 'https://github.com/sergiivelykodnyi/apple.nvim' }
vim.cmd.colorscheme 'apple'
```

With lazy.nvim:

```lua
{ 'sergiivelykodnyi/apple.nvim', priority = 1000, config = function() vim.cmd.colorscheme 'apple' end }
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
Force one on or off with `integrations = { name = true | false }`. If your
`init.lua` adds plugins after `:colorscheme apple`, the theme re-applies itself
once at `VimEnter`, so those plugins are picked up too.

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
| mint       | `#54DFCB` | `#008575` |
| teal       | `#3BDDEC` | `#008198` |
| cyan       | `#6DD9FF` | `#007EAE` |
| blue       | `#5CB8FF` | `#1E6EF4` |
| purple     | `#EA8DFF` | `#B02FC2` |
| pink       | `#FF8AC4` | `#E7124D` |
| brown      | `#DBA679` | `#956D51` |

Text colors are Apple's increased contrast colors; backgrounds and grays are
Apple's default ones. The tests keep every syntax color at a contrast of at
least 4.5 against the background in dark and 4.0 in light.

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
