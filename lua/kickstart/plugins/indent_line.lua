-- Add indentation guides even on blank lines

-- Enable `lukas-reineke/indent-blankline.nvim`
-- See `:help ibl`
vim.pack.add { 'https://github.com/lukas-reineke/indent-blankline.nvim' }
-- VSCode has no underline at the start and end of the active scope.
require('ibl').setup { scope = { show_start = false, show_end = false } }
