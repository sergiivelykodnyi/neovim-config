# Apple themes: two flavors with a contrast rule

Date: 2026-10-02 (revised the same day)

## Goal

Keep the `apple` themes at two flavors, dark and light, built from Apple
system colors, with text that is comfortable to read: enough contrast, but not
a harsh one. The themes exist for Neovim (`apple.nvim`), Ghostty and Warp.

## Decision record

The first version of this spec asked for four flavors: Apple's default colors
and Apple's increased contrast colors, each in dark and light. It was built
and then looked at on a real screen. The result:

- Light with default colors is hard to read. Yellow, orange, green and teal
  have a contrast of 1.4 to 2.1 against the background.
- Dark with default colors is readable (4.7 to 12.0), but the colors are very
  saturated and too strong on a bright 5K monitor.
- The full increased contrast flavors (with Apple's increased contrast grays
  as background) were not really "more contrast": the background gets
  lighter in dark mode, and bright terminal colors equal the normal ones.

So the four flavors and the `contrast` option are dropped. Both flavors use
the mix the themes had before: Apple's increased contrast colors for text, on
Apple's default backgrounds and grays. In dark mode these text colors are
lighter and less saturated; in light mode they are darker.

Source of the values:
[Apple HIG, Color, Specifications](https://developer.apple.com/design/human-interface-guidelines/color)
(June 2025 values). `apple.nvim/tests/hig.lua` holds all of them and was
checked against the page on 2026-10-01.

## Requirements

- Two flavors, `dark` and `light`. No `contrast` option and no extra theme
  files.
- Colors are the same as on `main` before this work, in Neovim, Ghostty and
  Warp.
- A contrast rule in the tests (WCAG contrast ratio against the background),
  so a weak color cannot come back:
  - syntax text colors: at least 4.5 in dark, at least 4.0 in light;
  - normal text: at least 7.0;
  - comments: at least 3.0;
  - text on search and selection backgrounds: at least 4.5.
- No pure white and no pure black background.
- The minimal Neovim config in `macos-configs` is removed. The `neovim-config`
  repository replaces it.

## Out of scope

- Increased contrast flavors and a `contrast` option.
- Following the macOS "Increase contrast" setting.
- Generating the Ghostty and Warp files from a script.
- A light background that reaches 4.5 for every syntax color. It would need a
  white background, which is not wanted.

## Colors

`mode` is `dark` or `light`. "default" and "increased" name the two columns of
Apple's table.

| Role | Apple color |
|---|---|
| `bg` | gray 6, default |
| `bg_alt` | gray 5, default |
| `border` | gray 3, default |
| `line_nr` | gray 2, default |
| `comment` | dark: gray, default (`#8E8E93`). Light: gray, increased (`#6C6C70`) |
| `fg` | `#F2F2F7` dark, `#1C1C1E` light |
| `red`, `orange`, `yellow`, `green`, `teal`, `blue`, `purple`, `pink` | same name, increased |
| `cursor` | indigo, default |
| `selection` / `selection_fg` | `#A7AAFF` / `#1C1C1E` |
| `search` / `cur_search` | yellow / orange, default, with `#1C1C1E` text |
| `diff_add`, `diff_change`, `diff_delete` | green, blue, red, default |

Contrast of the syntax text colors against `bg`: 5.8 to 12.8 in dark, 4.1 to
4.7 in light.

### Terminal colors (16 ANSI slots)

Slots 1-6 are red, green, yellow, blue, purple, cyan.

- Normal (1-6): increased contrast.
- Bright (9-14): default.
- Slots 0, 7, 8, 15 keep their values.

## apple.nvim (repository `neovim-config`)

- `palette.lua`, `config.lua`, `init.lua`, the README and the top-level
  `init.lua` are the same as on `main`. The `contrast` option, `palette.get()`,
  `palette.dark_contrast` and `palette.light_contrast` are removed.
- Tests are the same as on `main`, with one change: the check for syntax text
  colors in `palette_spec.lua` goes from 3.0 to 4.5 (dark) and 4.0 (light).
- The README gets a short note about the contrast rule.

## macos-configs

### Ghostty and Warp

`apple-dark`, `apple-light`, `apple_dark.yaml` and `apple_light.yaml` are the
same as on `main`. The four `-contrast` / `_contrast` files are removed. The
`theme =` line in the Ghostty `config` does not change.

### Remove the minimal Neovim config (kept from the first version)

- The `nvim/` stow package and its tests are deleted.
- The theme tests live in `tests/themes/` and run with
  `nvim --clean -l tests/themes/run.lua`.
- The README has an "APPLE THEMES" section with the test command and a note
  that the Neovim config lives in `neovim-config`. The "NEOVIM CONFIGURATION"
  section, including the `kvim` part, is gone.
- The old spec and plan for that config under `docs/superpowers/` stay as
  history.

Files with uncommitted user changes (`ghostty/.config/ghostty/config`,
`zsh/.zsh/aliases.zsh` and others) are not touched.

### Tests

`themes_spec.lua` runs for both flavors:

- every Ghostty file has all 16 colors and all base keys;
- normal slots are increased contrast, bright slots are default;
- black and white slots, background (gray 6), cursor (indigo), foreground,
  cursor text and selection have the values above;
- every Warp file has the same colors as its Ghostty file, the accent color
  and the right `details` value.

## Delivery

Two branches named `apple-contrast-flavors`, one per repository. They do not
depend on each other.
