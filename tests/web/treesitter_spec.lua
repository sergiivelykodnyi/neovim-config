local t = require 'web_helpers'

local installed = require('nvim-treesitter').get_installed 'parsers'
for _, parser in ipairs { 'html', 'css', 'scss', 'javascript', 'typescript', 'tsx', 'jsdoc', 'json' } do
  t.check('parser installed ' .. parser, vim.tbl_contains(installed, parser))
end

-- Highlighting starts by itself when a web file opens.
local root = t.plain_project()
for _, file in ipairs { 'src/a.js', 'src/a.jsx', 'src/a.ts', 'src/a.tsx', 'src/a.css', 'src/index.html', 'src/data.json' } do
  local buf = t.open(root .. '/' .. file)
  t.check('highlighting active in ' .. file, vim.treesitter.highlighter.active[buf] ~= nil)
end
