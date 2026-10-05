local t = require 'web_helpers'

-- Mason packages: language servers first, then CLI tools.
local packages = {
  'typescript-language-server',
  'html-lsp',
  'css-lsp',
  'json-lsp',
  'tailwindcss-language-server',
  'eslint-lsp',
  'stylelint-language-server',
  'prettierd',
  'eslint_d',
  'stylelint',
}
for _, name in ipairs(packages) do
  t.check('mason package ' .. name, require('mason-registry').is_installed(name))
end

for _, name in ipairs { 'ts_ls', 'html', 'cssls', 'jsonls', 'tailwindcss', 'eslint', 'stylelint_lsp' } do
  t.check('server enabled ' .. name, vim.lsp.is_enabled(name))
end

local css_settings = vim.lsp.config.cssls.settings or {}
for _, lang in ipairs { 'css', 'scss', 'less' } do
  t.check('cssls ignores unknown at-rules in ' .. lang, vim.tbl_get(css_settings, lang, 'lint', 'unknownAtRules') == 'ignore')
end
t.check('stylelint_lsp is limited to CSS files', vim.deep_equal(vim.lsp.config.stylelint_lsp.filetypes, { 'css', 'scss', 'less' }))

-- A project with lint configs: every server attaches to its file type.
local lint = t.lint_project()
local js = t.open(lint .. '/src/a.js')
t.check('ts_ls attaches to JS', t.attached(js, 'ts_ls'))
t.check('eslint attaches when a config exists', t.attached(js, 'eslint'))
local css = t.open(lint .. '/src/a.css')
t.check('cssls attaches to CSS', t.attached(css, 'cssls'))
t.check('stylelint_lsp attaches when a config exists', t.attached(css, 'stylelint_lsp'))
t.check('html attaches to HTML', t.attached(t.open(lint .. '/src/index.html'), 'html'))
t.check('jsonls attaches to tsconfig.json', t.attached(t.open(lint .. '/tsconfig.json'), 'jsonls'))

-- A project without lint configs: the lint servers stay away.
local plain = t.plain_project()
local plain_js = t.open(plain .. '/src/a.js')
t.check('ts_ls attaches without lint configs', t.attached(plain_js, 'ts_ls'))
t.check('eslint stays away without a config', not t.attached(plain_js, 'eslint', 3000))
local plain_css = t.open(plain .. '/src/a.css')
t.check('cssls attaches without lint configs', t.attached(plain_css, 'cssls'))
t.check('stylelint_lsp stays away without a config', not t.attached(plain_css, 'stylelint_lsp', 3000))
t.check('tailwindcss stays away outside Tailwind projects', not t.attached(plain_css, 'tailwindcss', 3000))
