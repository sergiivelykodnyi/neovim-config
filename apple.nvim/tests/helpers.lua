-- Small helpers for headless tests. No external test library is needed.
local M = { passed = 0, failed = 0 }

-- Run one test. An error inside fn marks the test as failed.
function M.test(name, fn)
  local ok, err = pcall(fn)
  if ok then
    M.passed = M.passed + 1
    print('ok   ' .. name)
  else
    M.failed = M.failed + 1
    print('FAIL ' .. name .. '\n     ' .. tostring(err))
  end
end

function M.eq(expected, actual, msg)
  if not vim.deep_equal(expected, actual) then error(('%s: expected %s, got %s'):format(msg or 'eq', vim.inspect(expected), vim.inspect(actual)), 2) end
end

function M.ok(value, msg)
  if not value then error(msg or 'expected a true value', 2) end
end

-- Convert a color number from nvim_get_hl() to '#RRGGBB'.
function M.hex(n) return n and ('#%06X'):format(n) or nil end

-- Forget loaded Lua modules, so the next require() reads the files again.
function M.unload(prefix)
  for name in pairs(package.loaded) do
    if name == prefix or vim.startswith(name, prefix .. '.') then package.loaded[name] = nil end
  end
end

-- Print a summary and return the exit code.
function M.report()
  print(('\n%d passed, %d failed'):format(M.passed, M.failed))
  return M.failed == 0 and 0 or 1
end

return M
