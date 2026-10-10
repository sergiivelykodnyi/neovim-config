-- rainbow-delimiters.nvim
-- https://github.com/HiPhish/rainbow-delimiters.nvim
--
-- Colors nested brackets by level, like VSCode bracket pair colorization.
-- The three groups match editorBracketHighlight.foreground1..3 of One Dark
-- Pro and are defined in lua/custom/plugins/colorscheme/groups/rainbow_delimiters.lua.

vim.g.rainbow_delimiters = {
  highlight = { 'RainbowDelimiterOrange', 'RainbowDelimiterViolet', 'RainbowDelimiterCyan' },
}

vim.pack.add { 'https://github.com/HiPhish/rainbow-delimiters.nvim' }
