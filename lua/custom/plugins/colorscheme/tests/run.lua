-- Test runner for the colorscheme.
-- Run from anywhere: nvim --clean -l lua/custom/plugins/colorscheme/tests/run.lua
local script = debug.getinfo(1, 'S').source:sub(2)
local tests_dir = vim.fn.fnamemodify(script, ':p:h')
-- tests -> colorscheme -> plugins -> custom -> lua -> repo root
local root = vim.fn.fnamemodify(tests_dir, ':h:h:h:h:h')

vim.opt.runtimepath:prepend(root)
package.path = tests_dir .. '/?.lua;' .. package.path

local t = require 'helpers'
local specs = vim.fn.glob(tests_dir .. '/*_spec.lua', false, true)
table.sort(specs)
for _, file in ipairs(specs) do
  print('\n# ' .. vim.fn.fnamemodify(file, ':t'))
  dofile(file)
end
os.exit(t.report())
