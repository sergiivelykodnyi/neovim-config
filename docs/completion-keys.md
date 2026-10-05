# Completion keys

Completion comes from [blink.cmp](https://github.com/saghen/blink.cmp) with
the `default` key preset. The menu opens by itself while you type in Insert
mode.

| Key                 | Action                                           |
| ------------------- | ------------------------------------------------ |
| `Ctrl-y`            | Accept the selected item                         |
| `Ctrl-n` or `Down`  | Select the next item                             |
| `Ctrl-p` or `Up`    | Select the previous item                         |
| `Ctrl-Space`        | Open the menu, or show the docs for the item     |
| `Ctrl-e`            | Close the menu                                   |
| `Ctrl-k`            | Show or hide the function signature help         |
| `Tab`               | Jump to the next field inside a snippet          |
| `Shift-Tab`         | Jump to the previous field inside a snippet      |

## Notes

- `Ctrl-y` also adds the import for the item, when the language server
  supports it.
- `Enter` and `Tab` do not accept an item in this preset.
- To change the keys, edit `preset` in the `blink.cmp` setup in `init.lua`
  (Section 8). Other presets are `enter` and `super-tab`. See
  `:help blink-cmp-config-keymap`.
