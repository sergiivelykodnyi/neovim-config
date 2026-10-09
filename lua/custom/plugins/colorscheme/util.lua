-- Helpers shared by the colorscheme.
local M = {}

-- True when a plugin is available.
-- `names` is a Lua module name ('telescope', 'blink.cmp') or a list of them.
-- A plugin counts as available when its module is already loaded, or when
-- lua/<name>.lua, lua/<name>/init.lua or lua/<name>/*.lua is on the runtimepath.
---@param names string|string[]
---@return boolean
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
---@param groups table<string, vim.api.keyset.highlight>
function M.apply(groups)
  for name, def in pairs(groups) do
    vim.api.nvim_set_hl(0, name, def)
  end
end

return M
