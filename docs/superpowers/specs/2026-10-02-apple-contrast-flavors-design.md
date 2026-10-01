# Apple themes: default and increased contrast flavors

Date: 2026-10-02

## Goal

Make the `apple` themes use Apple's **default** system colors, and offer
Apple's **increased contrast** colors as a second choice. This gives four
flavors: default dark, default light, increased contrast dark, increased
contrast light. They exist for Neovim (`apple.nvim`), Ghostty and Warp.

Today the themes are a mix: text colors are increased contrast values, while
backgrounds and grays are default values.

The themes are based on the colors Apple defines. Readability (contrast) is
**not** a requirement now. If a color looks poor in daily use, we fix it later.

Source of the values:
[Apple HIG, Color, Specifications](https://developer.apple.com/design/human-interface-guidelines/color)
(June 2025 values). `apple.nvim/tests/hig.lua` already holds all of them and
was checked against the page on 2026-10-01.

## Requirements

- Four flavors, each built only from Apple values.
- Default flavors are the default: with no new settings, Neovim, Ghostty and
  Warp show default colors.
- Neovim: a new `contrast` option picks the column. `flavor` works as before.
- Ghostty and Warp: one theme file per flavor.
- Tests check that every flavor uses the right Apple values.
- The minimal Neovim config in `macos-configs` is removed. The `neovim-config`
  repository replaces it.

## Out of scope

- Any contrast or readability rule. Existing contrast tests are removed.
- Following the macOS "Increase contrast" setting automatically.
- Generating the Ghostty and Warp files from a script.

## Colors

`column` is `default` or `increased contrast`. `mode` is `dark` or `light`.
A flavor is one column and one mode.

Roles that follow the flavor's column and mode:

| Role | Apple color |
|---|---|
| `bg` | gray 6 |
| `bg_alt` | gray 5 |
| `border` | gray 3 |
| `line_nr` | gray 2 |
| `comment` | gray |
| `red`, `orange`, `yellow`, `green`, `teal`, `blue`, `purple`, `pink` | same name |
| `cursor` | indigo |

So light comments become `#8E8E93` in the default flavor (today `#6C6C70`).

Roles that are the same in both columns (they follow only the mode):

| Role | Value |
|---|---|
| `fg` | `#F2F2F7` dark, `#1C1C1E` light |
| `selection` / `selection_fg` | `#A7AAFF` / `#1C1C1E` |
| `search` | default yellow |
| `cur_search` | default orange |
| `search_fg` | `#1C1C1E` |
| `diff_add`, `diff_change`, `diff_delete` | default green, blue, red |

Derived diff backgrounds are mixed from the diff colors and the flavor's `bg`,
as today.

### Terminal colors (16 ANSI slots)

Slots 1–6 are red, green, yellow, blue, purple, cyan. Slots 9–14 are the
bright versions.

| Flavor | Normal (1–6) | Bright (9–14) |
|---|---|---|
| default | default | increased contrast |
| increased contrast | increased contrast | increased contrast |

Slots 0, 7, 8, 15 keep today's values in all flavors.

## apple.nvim (repository `neovim-config`)

### Option

```lua
require('apple').setup {
  flavor = 'auto',       -- 'auto' | 'dark' | 'light' (unchanged)
  contrast = 'default',  -- 'default' | 'increased' (new)
}
```

Any other `contrast` value is treated as `'default'`.

### Palette

`lua/apple/palette.lua` changes from two hand-written tables to:

- one table with Apple's values, four columns per color (the same data as
  `tests/hig.lua`);
- one function `build(mode, contrast)` that returns a palette by the role
  tables above.

The module exposes `dark`, `light`, `dark_contrast`, `light_contrast` and
`get(mode, contrast)`. All four have the same keys as today, so the group files
and `on_highlights` need no change.

`lua/apple/init.lua` picks the palette with `get(flavor, opts.contrast)` in
both `do_load()` and `apply_new_integrations()`.

`tests/hig.lua` stays a separate copy. The tests compare the palette with it,
so a typo in one place is caught.

### Tests

- `palette_spec.lua` runs for all four flavors: format, role values against
  `hig.lua`, terminal slots, derived diff backgrounds, same keys everywhere.
- `config_spec.lua`: `contrast` default and merge.
- `colorscheme_spec.lua`: loading with `contrast = 'increased'` applies the
  increased contrast palette; changing the option and reloading switches it.
- `integrations_spec.lua` runs group checks for all four flavors.
- All `min_contrast` checks are removed, with the helper if nothing uses it.

### Docs

`apple.nvim/README.md`: four flavors, the `contrast` option, and a note that
the default light flavor has weak yellow, orange, green and teal text.

## macos-configs

### Ghostty

| File | Flavor |
|---|---|
| `themes/apple-dark` | default dark (values change) |
| `themes/apple-light` | default light (values change) |
| `themes/apple-dark-contrast` | increased contrast dark (new) |
| `themes/apple-light-contrast` | increased contrast light (new) |

`background`, `cursor-color` and the palette follow the role tables.
`cursor-text` stays `#1C1C1E`. The `theme =` line in `config` does not change.

### Warp

`apple_dark.yaml` and `apple_light.yaml` change to default values.
`apple_dark_contrast.yaml` and `apple_light_contrast.yaml` are new. Each has
the same colors as the Ghostty file of the same flavor. `accent` stays
`#A7AAFF`.

### Remove the minimal Neovim config

- Delete the `nvim/` stow package.
- Delete `tests/nvim/colorscheme_spec.lua`, `config_spec.lua`,
  `palette_spec.lua`.
- Move the rest to `tests/themes/` (`run.lua`, `helpers.lua`, `hig.lua`,
  `themes_spec.lua`). The runner no longer adds `nvim/` to the runtimepath.
  It still runs with `nvim --clean -l tests/themes/run.lua`.
- README: remove the "NEOVIM CONFIGURATION" section, including the `kvim`
  part. Keep a short note that the Neovim config lives in `neovim-config`,
  and the test command for the themes.
- The old spec and plan for that config under `docs/superpowers/` stay as
  history.

Files with uncommitted user changes (`ghostty/.config/ghostty/config`,
`zsh/.zsh/aliases.zsh` and others) are not touched.

### Tests

`themes_spec.lua` runs for all four flavors:

- Ghostty normal and bright slots match the terminal table above.
- Ghostty `background` is gray 6 and `cursor-color` is indigo of the flavor.
- Warp has the same colors as Ghostty.

## Delivery

Two branches and two pull requests, one per repository. They do not depend on
each other.
