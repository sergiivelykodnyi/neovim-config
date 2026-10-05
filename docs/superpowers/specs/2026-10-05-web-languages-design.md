# Web languages support: design

Date: 2026-10-05
Branch: `web-languages`

## Goal

Add good editing support for HTML, CSS, JavaScript and TypeScript to this
Neovim config. One key, `<leader>f`, must apply safe lint fixes first and
then format the buffer.

## What the user asked for

- Language servers, Mason tools, Treesitter parsers and linting for HTML,
  CSS, JS and TS.
- Automatic fixes for all lint issues that have a fix, through
  `<leader>f`.
- A small milestone with a spec, a plan and a pull request.

## Decisions

| Topic | Decision |
|---|---|
| Lint and format tools | ESLint + Prettier, Stylelint for CSS |
| How problems are shown | Language servers (ESLint, Stylelint) |
| How problems are fixed | Conform chain: lint fix, then Prettier |
| When the chain runs | Only on `<leader>f`. No format on save |
| TypeScript server | `ts_ls` |
| Extras | JSON support, Tailwind CSS, Stylelint |
| SCSS and Less | Included, same tools as CSS |
| Inline formatting problems | Not shown. `<leader>f` fixes them |

"JS and TS" includes JSX and TSX.

## Out of scope

- Format on save.
- `vtsls`, Emmet, Vue, Svelte, Astro, debugging.
- A custom linter that marks Prettier problems.
- Changes to Lua or Markdown behaviour.

## Current state

- Neovim 0.12.5, plugins through `vim.pack`, one `init.lua` in kickstart
  layout.
- Section 6 has a `servers` table (`lua_ls`, `stylua`). Its keys go to
  `mason-tool-installer`, then each server is set up with
  `vim.lsp.config` and `vim.lsp.enable`.
- Section 7 sets up `conform.nvim`. `formatters_by_ft` is empty,
  `lsp_format = 'fallback'`, format on save is off. `<leader>f` calls
  `conform.format { async = true }`.
- Section 9 installs Treesitter parsers from a list. `html` is in it.
- `lua/kickstart/plugins/lint.lua` runs `markdownlint` through
  `nvim-lint`.

## Design

All changes go into existing sections of `init.lua`. No new files and no
new plugins.

### Language servers (Section 6, `servers` table)

| Server | For | Settings |
|---|---|---|
| `ts_ls` | JS, JSX, TS, TSX | defaults |
| `html` | HTML | defaults |
| `cssls` | CSS, SCSS, Less | `lint.unknownAtRules = 'ignore'` for `css`, `scss`, `less` |
| `jsonls` | JSON, JSONC | defaults |
| `tailwindcss` | Tailwind class names | defaults |
| `eslint` | JS/TS diagnostics, code actions | defaults |
| `stylelint_lsp` | CSS diagnostics | `filetypes = { 'css', 'scss', 'less' }` |

Notes:

- The `cssls` setting stops false warnings for Tailwind rules such as
  `@apply` and `@tailwind`.
- The `eslint` and `stylelint_lsp` configs from `nvim-lspconfig` start
  only when the buffer has an ESLint or Stylelint config file above it.
  So projects without a config get no noise.
- `tailwindcss` starts only in projects that use Tailwind: a
  `tailwind.config.*` file, or a `package.json` that mentions
  `tailwindcss`. This needs our own `root_dir`, because the
  `nvim-lspconfig` default also starts in every git repository.
- No server needs its formatting turned off. Conform uses LSP formatting
  only as a fallback, and every web filetype gets an external formatter.

### Mason tools (Section 6, `ensure_installed`)

Add three CLI tools:

- `prettierd`: the formatter.
- `eslint_d`: applies ESLint fixes.
- `stylelint`: applies Stylelint fixes.

The servers install by themselves, because the keys of `servers` are
already part of `ensure_installed`.

### Formatting chain (Section 7, Conform)

`formatters_by_ft`:

| Filetypes | Chain |
|---|---|
| `javascript`, `javascriptreact`, `typescript`, `typescriptreact` | `eslint_d`, `prettierd` |
| `css`, `scss`, `less` | `stylelint`, `prettierd` |
| `html`, `json`, `jsonc` | `prettierd` |

Conform runs the formatters of a list in order. So the lint fix runs
first and Prettier formats its result.

Formatter overrides in `formatters`:

- `eslint_d`: `cwd` looks for ESLint config files (flat
  `eslint.config.*` and legacy `.eslintrc*`), and `require_cwd = true`.
- `stylelint`: `cwd` looks for Stylelint config files
  (`stylelint.config.*`, `.stylelintrc*`), and `require_cwd = true`.

Reason: the Conform defaults look for `package.json`, so the lint step
would run, and fail, in projects that have no lint config. With the
overrides the step is skipped and Prettier still runs.

The `format_on_save` function does not change. The `<leader>f` mapping
changes in one point: on a visual selection it skips the lint fixers and
runs Prettier only, because `eslint_d` and `stylelint` always change the
whole file.

### Treesitter (Section 9)

Add parsers: `css`, `scss`, `javascript`, `typescript`, `tsx`, `jsdoc`,
`json`.

### Linting (`nvim-lint`)

No change. It keeps Markdown only. ESLint and Stylelint problems come
from the language servers, which update while typing and offer code
actions.

### README

Add a short note: supported web languages, required tools (Node), and
what `<leader>f` does.

## Behaviour in edge cases

| Case | Result |
|---|---|
| No ESLint or Stylelint config | Lint step skipped, Prettier runs |
| No Prettier config | Prettier defaults |
| Lint issue with no automatic fix | Stays as a diagnostic |
| Syntax error in the file | Tool fails, buffer unchanged, see `:ConformInfo` |
| First start, tools not installed yet | Mason installs in the background |
| Project has its own `node_modules` tools | Conform prefers them over Mason's |

## Testing

1. Headless Neovim: the config loads without errors.
2. Headless Neovim: every new Mason package is installed.
3. Headless Neovim: Conform lists the expected chain for each filetype.
4. Fixture project in a temp folder (not committed) with ESLint and
   Stylelint configs and small JS, TS and CSS files that have fixable
   lint problems and bad formatting. Run the chain and compare with the
   expected text.
5. Same fixture without the lint configs: only Prettier changes apply and
   no error appears.
6. Each language server attaches to a sample file of its type. `eslint`
   and `stylelint_lsp` do not attach when the config is missing.
7. `stylua --check .` passes.
8. Manual check by the user: open a TS file, see diagnostics inline,
   press `<leader>f`.

## Delivery

1. Branch `web-languages` from `main`.
2. Commit the earlier local edits (lint, autopairs, indent line,
   `markdownlint`) as their own commit. Done.
3. Commit this spec.
4. Commit the implementation plan in `docs/superpowers/plans/`.
5. Implementation commits, with `nvim-pack-lock.json` if it changes.
6. Pull request to `main`.

Every commit ends with the line `Written by Claude`.
