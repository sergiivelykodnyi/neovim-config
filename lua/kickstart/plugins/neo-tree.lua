-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim

vim.pack.add {
  { src = 'https://github.com/nvim-neo-tree/neo-tree.nvim', version = vim.version.range '*' },
  'https://github.com/nvim-lua/plenary.nvim',
  'https://github.com/MunifTanjim/nui.nvim',
}

vim.keymap.set('n', '\\', '<Cmd>Neotree reveal<CR>', { desc = 'NeoTree reveal', silent = true })

require('neo-tree').setup {
  filesystem = {
    filtered_items = {
      -- Show dotfiles and git-ignored files as normal items
      hide_dotfiles = false,
      hide_gitignored = false,
      -- The .git folder is the only item that never shows
      never_show = { '.git' },
    },
    window = {
      mappings = {
        ['\\'] = 'close_window',
      },
    },
  },
}
