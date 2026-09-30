-- Small helpers shared by the apple colorscheme.
local M = {}

-- Mix two '#RRGGBB' colors. amount = 0 gives bg, amount = 1 gives fg.
function M.mix(fg, bg, amount)
  local channels = {}
  for i = 2, 6, 2 do
    local a = tonumber(fg:sub(i, i + 1), 16)
    local b = tonumber(bg:sub(i, i + 1), 16)
    channels[#channels + 1] = math.floor(a * amount + b * (1 - amount) + 0.5)
  end
  return ('#%02X%02X%02X'):format(channels[1], channels[2], channels[3])
end

-- True when a plugin is available.
-- `names` is a Lua module name ('telescope', 'blink.cmp') or a list of them.
-- A plugin counts as available when its module is already loaded, or when
-- lua/<name>.lua, lua/<name>/init.lua or lua/<name>/*.lua is on the runtimepath.
function M.has_plugin(names)
  if type(names) == 'string' then names = { names } end
  for _, name in ipairs(names) do
    if package.loaded[name] then return true end
    local path = 'lua/' .. name:gsub('%.', '/')
    for _, pattern in ipairs { path .. '.lua', path .. '/init.lua', path .. '/*.lua' } do
      if #vim.api.nvim_get_runtime_file(pattern, false) > 0 then return true end
    end
  end
  return false
end

-- Set every highlight group in the table.
function M.apply(groups)
  for name, def in pairs(groups) do
    vim.api.nvim_set_hl(0, name, def)
  end
end

return M
