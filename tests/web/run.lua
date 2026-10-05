-- Checks for the web languages setup (HTML, CSS, JS, TS).
-- They need the real config and the Mason tools, so they run locally only.
-- Run from the repo root: nvim --headless -c "luafile tests/web/run.lua"
local root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
package.path = root .. '/?.lua;' .. package.path

local t = require 'web_helpers'

-- Catch Lua errors, so a broken check cannot hang the headless editor.
local ok, err = xpcall(function()
  local specs = vim.fn.glob(root .. '/*_spec.lua', false, true)
  table.sort(specs)
  for _, file in ipairs(specs) do
    io.stdout:write('\n# ' .. vim.fn.fnamemodify(file, ':t') .. '\n')
    dofile(file)
  end
end, debug.traceback)

if not ok then io.stdout:write('ERROR ' .. tostring(err) .. '\n') end
io.stdout:write(('\n%d failed\n'):format(t.failed))
vim.cmd((ok and t.failed == 0) and 'qall!' or 'cquit 1')
