local t = require 'web_helpers'

-- Names of the formatters that will run for a file.
---@param path string
---@return string
local function chain(path)
  local names = vim.tbl_map(function(info) return info.name end, require('conform').list_formatters(t.open(path)))
  return table.concat(names, ',')
end

---@param name string
---@param got string
---@param want string
local function same(name, got, want) t.check(name, got == want, ('got %q, want %q'):format(got, want)) end

local lint = t.lint_project()
local plain = t.plain_project()

-- The chain for every file type, in a project with lint configs.
for _, ext in ipairs { 'js', 'jsx', 'ts', 'tsx' } do
  same('chain for .' .. ext, chain(lint .. '/src/a.' .. ext), 'eslint_d,prettierd')
end
for _, ext in ipairs { 'css', 'scss', 'less' } do
  same('chain for .' .. ext, chain(lint .. '/src/a.' .. ext), 'stylelint,prettierd')
end
same('chain for .html', chain(lint .. '/src/index.html'), 'prettierd')
same('chain for .json', chain(lint .. '/src/data.json'), 'prettierd')
same('chain for tsconfig.json', chain(lint .. '/tsconfig.json'), 'prettierd')

-- Without lint configs the lint step is skipped.
same('chain for .js without ESLint config', chain(plain .. '/src/a.js'), 'prettierd')
same('chain for .css without Stylelint config', chain(plain .. '/src/a.css'), 'prettierd')

-- Lint fixes first, then Prettier. Problems with no fix stay in the file.
same('JS: ESLint fix, then Prettier', t.format(lint .. '/src/a.js'), 'const a = 1;\nconst unused = 2;\nconsole.log(a);\n')
same('CSS: Stylelint fix, then Prettier', t.format(lint .. '/src/a.css'), 'a {\n  color: #fff;\n  margin: 0;\n  border-color: red;\n}\n')
same('HTML: Prettier', t.format(lint .. '/src/index.html'), '<div>\n  <p>hi</p>\n</div>\n')
same('JSON: Prettier', t.format(lint .. '/src/data.json'), '{ "a": 1 }\n')
same('JSON with comments keeps them', t.format(lint .. '/tsconfig.json'), '{\n  // keep me\n  "compilerOptions": { "strict": true }\n}\n')

-- Without lint configs only Prettier changes the file.
same('JS without ESLint config: Prettier only', t.format(plain .. '/src/a.js'), 'let a = 1;\nlet unused = 2;\nconsole.log(a);\n')
same('CSS without Stylelint config: Prettier only', t.format(plain .. '/src/a.css'), 'a {\n  color: #ffffff;\n  margin: 0px;\n  border-color: red;\n}\n')

-- A lint config inside package.json also counts.
local in_package = t.project {
  ['package.json'] = '{ "stylelint": { "rules": { "color-hex-length": "short" } } }\n',
  ['src/a.css'] = 'a { color: #ffffff }\n',
}
same('chain with Stylelint config in package.json', chain(in_package .. '/src/a.css'), 'stylelint,prettierd')
same('CSS with Stylelint config in package.json', t.format(in_package .. '/src/a.css'), 'a {\n  color: #fff;\n}\n')

-- A syntax error leaves the buffer as it is and raises no Lua error.
local ok, result = pcall(t.format, lint .. '/src/broken.js')
t.check('syntax error raises no Lua error', ok, tostring(result))
same('syntax error leaves the buffer unchanged', ok and result or '', 'const = ;\n')

-- Saving a file does not format it.
local buf = t.open(plain .. '/src/a.ts')
vim.cmd 'silent write!'
same('no format on save', t.text(buf), 'let  a = 1\n')
