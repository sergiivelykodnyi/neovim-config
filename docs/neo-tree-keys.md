# Neo-tree keys

The file tree comes from
[neo-tree.nvim](https://github.com/nvim-neo-tree/neo-tree.nvim). It shows all
files. Dotfiles and git-ignored files are dimmed, and `H` hides them. The
`.git` folder is always hidden.

The keys below work in Normal mode. All of them except the first one work
only inside the tree window.

## Open and close

| Key   | Action                                                 |
| ----- | ------------------------------------------------------ |
| `\`   | Open the tree on the current file, or close the tree   |
| `q`   | Close the tree                                         |
| `?`   | Show all keys                                          |

## Move around

| Key         | Action                                           |
| ----------- | ------------------------------------------------ |
| `j` / `k`   | Move down / up                                   |
| `Space`     | Open or close the folder                         |
| `C`         | Close the folder                                 |
| `z`         | Close all folders                                |
| `Backspace` | Go to the parent folder                          |
| `.`         | Make the folder under the cursor the tree root   |
| `/`         | Fuzzy search for a file or folder                |
| `Ctrl-x`    | Clear the search filter                          |
| `[g` / `]g` | Jump to the previous / next file changed in git  |
| `H`         | Hide or show dotfiles and git-ignored files      |
| `R`         | Refresh the tree                                 |

## Open files

| Key     | Action                                    |
| ------- | ----------------------------------------- |
| `Enter` | Open the file, or open / close the folder |
| `s`     | Open in a vertical split                  |
| `S`     | Open in a horizontal split                |
| `t`     | Open in a new tab                         |
| `P`     | Show or hide a preview of the file        |

## Change files

| Key | Action                                                    |
| --- | --------------------------------------------------------- |
| `a` | Add a file. End the name with `/` to add a folder         |
| `A` | Add a folder                                              |
| `r` | Rename                                                    |
| `d` | Delete                                                    |
| `c` | Copy to a new path that you type                          |
| `m` | Move to a new path that you type                          |
| `y` | Mark to copy                                              |
| `x` | Mark to move                                              |
| `p` | Paste the marked items into the folder under the cursor   |
| `i` | Show file details (size, dates)                           |

## Notes

- `a` in a folder creates the new file inside this folder. You can type a
  path like `a/b/c.lua`, the missing folders are created too.
- `H` never shows the `.git` folder.
- To change the tree, edit `lua/kickstart/plugins/neo-tree.lua`. See
  `:help neo-tree-mappings` for all commands.
