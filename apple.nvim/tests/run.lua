-- Test runner for apple.nvim.
-- Run from anywhere: nvim --clean -l apple.nvim/tests/run.lua
local script = debug.getinfo(1, 'S').source:sub(2)
local root = vim.fn.fnamemodify(script, ':p:h:h')

vim.opt.runtimepath:prepend(root)
package.path = root .. '/tests/?.lua;' .. package.path

local t = require 'helpers'
local specs = vim.fn.glob(root .. '/tests/*_spec.lua', false, true)
table.sort(specs)
for _, file in ipairs(specs) do
  print('\n# ' .. vim.fn.fnamemodify(file, ':t'))
  dofile(file)
end
os.exit(t.report())
