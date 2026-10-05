-- Helpers for the web languages checks.
local M = { failed = 0 }

-- Print one result line and count the failures.
---@param name string
---@param ok boolean
---@param detail? string
function M.check(name, ok, detail)
  if ok then
    io.stdout:write('ok   ' .. name .. '\n')
    return
  end
  M.failed = M.failed + 1
  io.stdout:write('FAIL ' .. name .. (detail and (' -- ' .. detail) or '') .. '\n')
end

-- Create a temp project from a { path = text } table and return its root.
---@param files table<string, string>
---@return string
function M.project(files)
  local root = vim.fn.resolve(vim.fn.tempname())
  for path, text in pairs(files) do
    local full = root .. '/' .. path
    vim.fn.mkdir(vim.fs.dirname(full), 'p')
    local file = assert(io.open(full, 'w'))
    file:write(text)
    file:close()
  end
  return root
end

-- Source files with lint problems and bad formatting.
local sources = {
  -- A fake `.git` folder: most projects are git repositories.
  ['.git/HEAD'] = 'ref: refs/heads/main\n',
  ['package.json'] = '{}\n',
  ['package-lock.json'] = '{}\n',
  -- `unused` has a lint problem with no automatic fix.
  ['src/a.js'] = 'let  a = 1\nlet unused = 2\nconsole.log( a )\n',
  ['src/a.jsx'] = 'let  a = 1\n',
  ['src/a.ts'] = 'let  a = 1\n',
  ['src/a.tsx'] = 'let  a = 1\n',
  -- `red` has a lint problem with no automatic fix.
  ['src/a.css'] = 'a { color: #ffffff; margin: 0px; border-color: red }\n',
  ['src/a.scss'] = 'a { color: #ffffff }\n',
  ['src/a.less'] = 'a { color: #ffffff }\n',
  ['src/index.html'] = '<div>\n<p>hi</p>\n      </div>\n',
  ['src/data.json'] = '{"a":1}\n',
  ['src/broken.js'] = 'const = ;\n',
  ['src/range.js'] = 'let  a = 1\nlet  b = 2\nlet  c = 3\nconsole.log( a, b, c )\n',
  ['tsconfig.json'] = '{\n  // keep me\n  "compilerOptions": {"strict":true}\n}\n',
}

-- A project with ESLint and Stylelint configs at its root.
---@return string
function M.lint_project()
  local files = vim.deepcopy(sources)
  files['eslint.config.mjs'] = "export default [{ rules: { 'prefer-const': 'error', 'no-unused-vars': 'error' } }];\n"
  files['.stylelintrc.json'] = '{ "rules": { "color-hex-length": "short", "length-zero-no-unit": true, "color-named": "never" } }\n'
  return M.project(files)
end

-- The same project without any lint config.
---@return string
function M.plain_project() return M.project(vim.deepcopy(sources)) end

-- Open a file and return its buffer number.
---@param path string
---@return integer
function M.open(path)
  vim.cmd.edit(vim.fn.fnameescape(path))
  return vim.api.nvim_get_current_buf()
end

-- Buffer text as one string with a final newline.
---@param buf integer
---@return string
function M.text(buf) return table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), '\n') .. '\n' end

-- Run the same chain as `<leader>f`, but wait for the result.
---@param path string
---@return string
function M.format(path)
  local buf = M.open(path)
  require('conform').format { bufnr = buf, async = false, timeout_ms = 20000 }
  return M.text(buf)
end

-- Wait until the named language server is attached to the buffer.
---@param buf integer
---@param name string
---@param timeout_ms? integer
---@return boolean
function M.attached(buf, name, timeout_ms)
  -- Keep only the first result of `vim.wait`; the second one is an error code.
  local ok = vim.wait(timeout_ms or 20000, function() return #vim.lsp.get_clients { bufnr = buf, name = name } > 0 end, 100)
  return ok
end

return M
