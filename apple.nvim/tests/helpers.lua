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
  if not vim.deep_equal(expected, actual) then
    error(('%s: expected %s, got %s'):format(msg or 'eq', vim.inspect(expected), vim.inspect(actual)), 2)
  end
end

function M.ok(value, msg)
  if not value then error(msg or 'expected a true value', 2) end
end

-- WCAG relative luminance of one color channel (0-255).
local function channel(c)
  c = c / 255
  return c <= 0.03928 and c / 12.92 or ((c + 0.055) / 1.055) ^ 2.4
end

local function luminance(hex)
  local r = tonumber(hex:sub(2, 3), 16)
  local g = tonumber(hex:sub(4, 5), 16)
  local b = tonumber(hex:sub(6, 7), 16)
  return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)
end

-- WCAG contrast ratio between two '#RRGGBB' colors (1 to 21).
function M.contrast(a, b)
  local x, y = luminance(a), luminance(b)
  if x < y then x, y = y, x end
  return (x + 0.05) / (y + 0.05)
end

function M.min_contrast(fg, bg, min, label)
  local ratio = M.contrast(fg, bg)
  if ratio < min then error(('%s: %s on %s has %.2f:1, needs %.1f:1'):format(label, fg, bg, ratio, min), 2) end
end

-- Convert a color number from nvim_get_hl() to '#RRGGBB'.
function M.hex(n)
  return n and ('#%06X'):format(n) or nil
end

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
