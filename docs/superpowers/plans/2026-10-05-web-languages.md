# Web Languages Support Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add HTML, CSS, JS and TS support to this Neovim config, with one key (`<leader>f`) that applies lint fixes first and then formats.

**Architecture:** Everything goes into existing sections of `init.lua`. Language servers show problems (Section 6), Conform runs the fix chain `eslint_d`/`stylelint` → `prettierd` (Section 7), Treesitter gets new parsers (Section 9). A small local test runner in `tests/web/` proves each part against temp fixture projects.

**Tech Stack:** Neovim 0.12.5, `vim.pack`, `nvim-lspconfig`, `mason.nvim`, `mason-tool-installer.nvim`, `conform.nvim`, `nvim-treesitter` (main branch), Node 24.

**Spec:** `docs/superpowers/specs/2026-10-05-web-languages-design.md`

## Global Constraints

- Work on branch `web-languages`. Do not commit to `main`.
- `~/.config/nvim` is a symlink to this repo, so `nvim --headless` loads the code of the current branch.
- No new plugins and no new config files. Only `init.lua`, `README.md` and `tests/web/` change.
- No format on save. `format_on_save` in Section 7 must not change.
- TypeScript server is `ts_ls`. Do not add `vtsls`, Emmet, Vue, Svelte or Astro.
- `nvim-lint` keeps Markdown only. Do not touch `lua/kickstart/plugins/lint.lua`.
- Lua style: 2 spaces, single quotes, no call parentheses for one string or table argument, column width 160 (`.stylua.toml`). CI runs `stylua --check .`, and this includes `tests/web/`.
- Comments are short and in simple English.
- Every commit message ends with exactly one trailer line: `Written by Claude`. No email address, no `Co-Authored-By`, no session link. A subagent that commits must get this rule in its prompt.
- Run all commands from the repo root: `/Users/sergii/github/personal/neovim-config`.
- Stylua binary: `~/.local/share/nvim/mason/bin/stylua`.

## Review Focus

Inputs the spec implies but does not spell out. Each one has a check in Task 3.

1. Lint config stored inside `package.json` (key `stylelintConfig` or `eslintConfig`): the lint fix must still run.
2. A file with a lint problem that has no automatic fix: the other fixes and Prettier must still apply.
3. A file with a syntax error: the buffer must stay unchanged and no Lua error may appear.
4. A file in a nested folder (`src/`), with the configs at the project root: the chain must find the configs.
5. A JSON file with comments (`tsconfig.json`): formatting must keep the comments.

## File Structure

| File | Role |
|---|---|
| `init.lua` (modify) | Section 6: servers and Mason tools. Section 7: Conform chain. Section 9: parsers. |
| `tests/web/run.lua` (create) | Runner. Loads every `*_spec.lua` in its folder, prints results, sets the exit code. |
| `tests/web/web_helpers.lua` (create) | `check`, fixture projects, `open`, `format`, `attached`. |
| `tests/web/lsp_spec.lua` (create) | Mason packages, enabled servers, server attach. |
| `tests/web/treesitter_spec.lua` (create) | Parsers installed and highlighting active. |
| `tests/web/format_spec.lua` (create) | Conform chains and fixture results. |
| `README.md` (modify) | Short "Web Languages" section. |

The tests need the real config, Mason tools and a network on first run, so they run locally only. They are not added to CI.

Run the tests with:

```bash
nvim --headless -c "luafile tests/web/run.lua"; echo "exit=$?"
```

---

### Task 1: Test runner, language servers and Mason tools

**Files:**
- Create: `tests/web/run.lua`, `tests/web/web_helpers.lua`, `tests/web/lsp_spec.lua`
- Modify: `init.lua` Section 6 (`servers` table near line 768, `ensure_installed` near line 828)

**Interfaces:**
- Produces, from `tests/web/web_helpers.lua` (used by Tasks 2 and 3):
  - `t.check(name: string, ok: boolean, detail?: string)`
  - `t.lint_project(): string` — root of a temp project with ESLint and Stylelint configs
  - `t.plain_project(): string` — root of a temp project without lint configs
  - `t.project(files: table<string, string>): string` — root of a temp project made from `{ path = text }`
  - `t.open(path: string): integer` — buffer number
  - `t.text(buf: integer): string` — buffer text with a final newline
  - `t.format(path: string): string` — text after the `<leader>f` chain
  - `t.attached(buf: integer, name: string, timeout_ms?: integer): boolean`
  - `t.failed: integer`

- [ ] **Step 1: Write the runner**

Create `tests/web/run.lua`:

```lua
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
```

- [ ] **Step 2: Write the helpers**

Create `tests/web/web_helpers.lua`:

```lua
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
  return vim.wait(timeout_ms or 20000, function() return #vim.lsp.get_clients { bufnr = buf, name = name } > 0 end, 100)
end

return M
```

- [ ] **Step 3: Write the failing LSP checks**

Create `tests/web/lsp_spec.lua`:

```lua
local t = require 'web_helpers'

-- Mason packages: language servers first, then CLI tools.
local packages = {
  'typescript-language-server',
  'html-lsp',
  'css-lsp',
  'json-lsp',
  'tailwindcss-language-server',
  'eslint-lsp',
  'stylelint-lsp',
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
```

- [ ] **Step 4: Run the checks and see them fail**

Run: `nvim --headless -c "luafile tests/web/run.lua"; echo "exit=$?"`

Expected: many `FAIL` lines (packages, enabled servers) or one `ERROR` line about `vim.lsp.config.stylelint_lsp`, and `exit=1`.

- [ ] **Step 5: Add the servers**

In `init.lua` Section 6, find this line in the `servers` table:

```lua
    stylua = {}, -- Used to format Lua code
```

Add after it:

```lua

    -- Web languages: JavaScript, TypeScript, HTML, CSS, JSON
    ts_ls = {},
    html = {},
    jsonls = {},
    tailwindcss = {}, -- Starts only in projects that use Tailwind CSS
    eslint = {}, -- Starts only in projects with an ESLint config
    cssls = {
      settings = {
        -- Tailwind adds rules like `@apply`, so do not warn about unknown at-rules
        css = { lint = { unknownAtRules = 'ignore' } },
        scss = { lint = { unknownAtRules = 'ignore' } },
        less = { lint = { unknownAtRules = 'ignore' } },
      },
    },
    stylelint_lsp = {
      filetypes = { 'css', 'scss', 'less' }, -- Starts only in projects with a Stylelint config
    },
```

- [ ] **Step 6: Add the Mason tools**

In `init.lua` Section 6, find:

```lua
    'markdownlint', -- Used to lint Markdown files
```

Add after it:

```lua
    'prettierd', -- Used to format web files (HTML, CSS, JS, TS, JSON)
    'eslint_d', -- Used to apply ESLint fixes
    'stylelint', -- Used to apply Stylelint fixes
```

- [ ] **Step 7: Install the tools**

Run: `nvim --headless -c "MasonToolsInstallSync" -c "qall"`

Expected: install messages for ten packages, no error. This can take a few minutes.

- [ ] **Step 8: Run the checks and see them pass**

Run: `nvim --headless -c "luafile tests/web/run.lua"; echo "exit=$?"`

Expected: only `ok` lines, `0 failed`, `exit=0`.

If an attach check fails, open the file by hand and read `:checkhealth vim.lsp` before changing the check.

- [ ] **Step 9: Check the style and commit**

```bash
~/.local/share/nvim/mason/bin/stylua --check .
git add init.lua tests/web
git commit -m "Add language servers and tools for web languages

Add ts_ls, html, cssls, jsonls, tailwindcss, eslint and stylelint_lsp.
Install prettierd, eslint_d and stylelint with Mason.
Add a local test runner in tests/web.

Written by Claude"
```

Expected: stylua prints nothing. If it reports a file, run `stylua` on it and check again.

---

### Task 2: Treesitter parsers

**Files:**
- Create: `tests/web/treesitter_spec.lua`
- Modify: `init.lua` Section 9 (the `parsers` list near line 973)

**Interfaces:**
- Consumes: `t.check`, `t.plain_project`, `t.open` from `tests/web/web_helpers.lua`.
- Produces: nothing for later tasks.

- [ ] **Step 1: Write the failing checks**

Create `tests/web/treesitter_spec.lua`:

```lua
local t = require 'web_helpers'

local installed = require('nvim-treesitter').get_installed 'parsers'
for _, parser in ipairs { 'html', 'css', 'scss', 'javascript', 'typescript', 'tsx', 'jsdoc', 'json' } do
  t.check('parser installed ' .. parser, vim.tbl_contains(installed, parser))
end

-- Highlighting starts by itself when a web file opens.
local root = t.plain_project()
for _, file in ipairs { 'src/a.js', 'src/a.jsx', 'src/a.ts', 'src/a.tsx', 'src/a.css', 'src/index.html', 'src/data.json' } do
  local buf = t.open(root .. '/' .. file)
  t.check('highlighting active in ' .. file, vim.treesitter.highlighter.active[buf] ~= nil)
end
```

- [ ] **Step 2: Run the checks and see them fail**

Run: `nvim --headless -c "luafile tests/web/run.lua"; echo "exit=$?"`

Expected: `FAIL parser installed css` and more parser lines, `exit=1`. The `lsp_spec.lua` lines stay `ok`.

- [ ] **Step 3: Add the parsers**

In `init.lua` Section 9, replace this line:

```lua
  local parsers = { 'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc' }
```

with:

```lua
  local parsers = { 'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc' }
  -- Parsers for web languages
  vim.list_extend(parsers, { 'css', 'scss', 'javascript', 'typescript', 'tsx', 'jsdoc', 'json' })
```

- [ ] **Step 4: Install the parsers**

The config installs parsers in the background, so a headless run must wait for it:

```bash
nvim --headless -c "lua require('nvim-treesitter').install({ 'css', 'scss', 'javascript', 'typescript', 'tsx', 'jsdoc', 'json' }):wait(300000)" -c "qall"
```

Expected: no error.

- [ ] **Step 5: Run the checks and see them pass**

Run: `nvim --headless -c "luafile tests/web/run.lua"; echo "exit=$?"`

Expected: `0 failed`, `exit=0`.

- [ ] **Step 6: Check the style and commit**

```bash
~/.local/share/nvim/mason/bin/stylua --check .
git add init.lua tests/web/treesitter_spec.lua
git commit -m "Add Treesitter parsers for web languages

Written by Claude"
```

---

### Task 3: Lint fix and format chain on `<leader>f`

**Files:**
- Create: `tests/web/format_spec.lua`
- Modify: `init.lua` Section 7 (near lines 843-875)

**Interfaces:**
- Consumes: `t.check`, `t.project`, `t.lint_project`, `t.plain_project`, `t.open`, `t.text`, `t.format` from `tests/web/web_helpers.lua`. Mason tools `prettierd`, `eslint_d`, `stylelint` from Task 1.
- Produces: nothing for later tasks.

Background for the implementer:

- Conform runs the formatters of a list in order. `{ 'eslint_d', 'prettierd' }` means ESLint fixes first, then Prettier.
- A Conform formatter with `require_cwd = true` is skipped when its `cwd` function returns `nil`. The built-in `eslint_d` and `stylelint` formatters look for `package.json`. We replace that with a search for real lint config files.
- `conform.list_formatters(buf)` returns only the formatters that can run for that buffer. So in a project without an ESLint config it must return `prettierd` alone.

- [ ] **Step 1: Write the failing checks**

Create `tests/web/format_spec.lua`:

```lua
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
  ['package.json'] = '{ "stylelintConfig": { "rules": { "color-hex-length": "short" } } }\n',
  ['src/a.css'] = 'a { color: #ffffff }\n',
}
same('chain with stylelintConfig in package.json', chain(in_package .. '/src/a.css'), 'stylelint,prettierd')
same('CSS with stylelintConfig in package.json', t.format(in_package .. '/src/a.css'), 'a {\n  color: #fff;\n}\n')

-- A syntax error leaves the buffer as it is and raises no Lua error.
local ok, result = pcall(t.format, lint .. '/src/broken.js')
t.check('syntax error raises no Lua error', ok, tostring(result))
same('syntax error leaves the buffer unchanged', ok and result or '', 'const = ;\n')

-- Saving a file does not format it.
local buf = t.open(plain .. '/src/a.ts')
vim.cmd 'silent write!'
same('no format on save', t.text(buf), 'let  a = 1\n')
```

- [ ] **Step 2: Run the checks and see them fail**

Run: `nvim --headless -c "luafile tests/web/run.lua"; echo "exit=$?"`

Expected: `FAIL chain for .js -- got "", want "eslint_d,prettierd"` and more lines in `format_spec.lua`, `exit=1`. The checks `no format on save` and `syntax error ...` pass already. The other spec files stay `ok`.

- [ ] **Step 3: Add the chain to Conform**

In `init.lua` Section 7, find:

```lua
  -- [[ Formatting ]]
  vim.pack.add { gh 'stevearc/conform.nvim' }
```

Add after it:

```lua

  -- Find the project root for a lint tool: the nearest folder with one of its
  -- config files, or with a package.json that has the tool's config key.
  -- Without a root the lint step is skipped (see `require_cwd` below).
  ---@param files string[]
  ---@param package_key string
  local function lint_root(files, package_key)
    return function(_, ctx)
      return vim.fs.root(ctx.dirname, function(name, path)
        if vim.tbl_contains(files, name) then return true end
        if name ~= 'package.json' then return false end
        local file = io.open(vim.fs.joinpath(path, name), 'r')
        if not file then return false end
        local ok, data = pcall(vim.json.decode, file:read '*a')
        file:close()
        return ok and type(data) == 'table' and data[package_key] ~= nil
      end)
    end
  end

  local eslint_configs = {
    'eslint.config.js',
    'eslint.config.mjs',
    'eslint.config.cjs',
    'eslint.config.ts',
    'eslint.config.mts',
    'eslint.config.cts',
    '.eslintrc',
    '.eslintrc.js',
    '.eslintrc.cjs',
    '.eslintrc.json',
    '.eslintrc.yaml',
    '.eslintrc.yml',
  }
  local stylelint_configs = {
    'stylelint.config.js',
    'stylelint.config.mjs',
    'stylelint.config.cjs',
    '.stylelintrc',
    '.stylelintrc.js',
    '.stylelintrc.mjs',
    '.stylelintrc.cjs',
    '.stylelintrc.json',
    '.stylelintrc.yaml',
    '.stylelintrc.yml',
  }

  -- Lint fixes run first, then Prettier formats the result
  local script_chain = { 'eslint_d', 'prettierd' }
  local style_chain = { 'stylelint', 'prettierd' }
```

Then replace the whole `formatters_by_ft` block:

```lua
    formatters_by_ft = {
      -- rust = { 'rustfmt' },
      -- Conform can also run multiple formatters sequentially
      -- python = { "isort", "black" },
      --
      -- You can use 'stop_after_first' to run the first available formatter from the list
      -- javascript = { "prettierd", "prettier", stop_after_first = true },
    },
```

with:

```lua
    formatters_by_ft = {
      -- rust = { 'rustfmt' },
      -- Conform can also run multiple formatters sequentially
      -- python = { "isort", "black" },
      --
      -- You can use 'stop_after_first' to run the first available formatter from the list
      -- javascript = { "prettierd", "prettier", stop_after_first = true },
      javascript = script_chain,
      javascriptreact = script_chain,
      typescript = script_chain,
      typescriptreact = script_chain,
      css = style_chain,
      scss = style_chain,
      less = style_chain,
      html = { 'prettierd' },
      json = { 'prettierd' },
      jsonc = { 'prettierd' },
    },
    formatters = {
      -- Run the lint fixers only in projects that have a config for them
      eslint_d = { cwd = lint_root(eslint_configs, 'eslintConfig'), require_cwd = true },
      stylelint = { cwd = lint_root(stylelint_configs, 'stylelintConfig'), require_cwd = true },
    },
```

Do not change `format_on_save`, `default_format_opts` or the `<leader>f` mapping.

- [ ] **Step 4: Run the checks and see them pass**

Run: `nvim --headless -c "luafile tests/web/run.lua"; echo "exit=$?"`

Expected: `0 failed`, `exit=0`.

If a fixture result differs, look at the real tool output before changing anything:

```bash
nvim --headless -c "edit <fixture path>" -c "lua require('conform').format({ async = false, timeout_ms = 20000 })" -c "ConformInfo" -c "qall"
```

`:ConformInfo` shows the log path. Fix the config when the chain is wrong. Change the expected text only when the tool is right and the expectation was wrong (for example, a newer Prettier prints JSON in another way). Say so in the commit message.

- [ ] **Step 5: Check the style and commit**

```bash
~/.local/share/nvim/mason/bin/stylua --check .
git add init.lua tests/web/format_spec.lua
git commit -m "Run lint fixes and Prettier on <leader>f for web files

JS and TS files run eslint_d, then prettierd.
CSS, SCSS and Less files run stylelint, then prettierd.
HTML and JSON files run prettierd.
The lint step is skipped in projects without a lint config.

Written by Claude"
```

---

### Task 4: README, final checks and pull request

**Files:**
- Modify: `README.md` (before the `## Installation` heading, near line 13)

**Interfaces:**
- Consumes: the finished work of Tasks 1-3.
- Produces: the pull request.

- [ ] **Step 1: Add the README section**

In `README.md`, add before the line `## Installation`:

```markdown
## Web Languages

This config supports HTML, CSS (also SCSS and Less), JavaScript, TypeScript,
JSX, TSX and JSON. It needs [Node.js](https://nodejs.org), because Mason
installs the tools with `npm`.

* Language servers: `ts_ls`, `html`, `cssls`, `jsonls`, `tailwindcss`,
  `eslint`, `stylelint_lsp`. They show problems inline while you type.
* `<leader>f` applies lint fixes first (`eslint_d` or `stylelint`) and then
  formats with `prettierd`. Nothing is formatted on save.
* ESLint, Stylelint and Tailwind tools start only in projects that have a
  config for them.

Run the local checks with:

    nvim --headless -c "luafile tests/web/run.lua"

```

- [ ] **Step 2: Run every check**

```bash
nvim --headless -c "luafile tests/web/run.lua"; echo "exit=$?"
nvim --clean -l apple.nvim/tests/run.lua; echo "exit=$?"
~/.local/share/nvim/mason/bin/stylua --check .; echo "exit=$?"
nvim --headless -c "qall" 2>&1
git status --short
```

Expected: `0 failed` and `exit=0` for the web checks, `exit=0` for the apple tests and stylua, no output from the plain start, and only `README.md` in `git status`. If `nvim-pack-lock.json` shows a change, look at the diff. No new plugin was added, so a change there is not expected; do not commit it without a reason.

- [ ] **Step 3: Commit the README**

```bash
git add README.md
git commit -m "Describe web languages support in the README

Written by Claude"
```

- [ ] **Step 4: Push and open the pull request**

Read `.github/pull_request_template.md` first and follow its layout.

```bash
git push -u origin web-languages
gh pr create --base main --head web-languages --title "Add web languages support (HTML, CSS, JS, TS)" --body-file <path to the body file>
```

The body must cover: what changed (servers, Mason tools, Treesitter parsers, the `<leader>f` chain), what did not change (no format on save, `nvim-lint` keeps Markdown only), how it was tested (the `tests/web` runner and its result), and links to the spec and this plan. End the body with this line:

```
🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

- [ ] **Step 5: Hand over the manual check**

Tell the user the PR link and ask for this manual check in a real project:

1. Open a `.ts` file. Type errors and ESLint problems appear inline.
2. Press `<leader>f`. Fixable lint problems go away and the file is formatted.
3. Save with `:w`. Nothing is formatted.
4. Open a `.css` file in a project without a Stylelint config. `<leader>f` only formats it.
