# One Dark Pro Night Flat colorscheme: design

Date: 2026-10-09
Branch: `onedark-colorscheme`

## Goal

Make Neovim look exactly like VSCode with the "One Dark Pro Night Flat" theme
from [Binaryify/OneDark-Pro](https://github.com/Binaryify/OneDark-Pro). The
Ghostty terminal already uses this palette (`ghostty/themes/one-dark` in the
`macos-configs` repo), so terminal and editor match.

## What the user asked for

- A standalone theme, built from scratch. It does not depend on apple.nvim
  and does not take color choices from it.
- The same plugin integrations as apple.nvim.
- Location: `lua/custom/plugins/colorscheme/`, loaded with
  `require 'custom.plugins.colorscheme'` as kickstart recommends.
- Exact colors. Side-by-side screenshots with VSCode verify the result.
- Tests and a CI workflow, like apple.nvim had.
- apple.nvim moves out of this repo to `../apple.nvim`, together with its
  CI workflow, spec and plan.

## Decisions

| Topic | Decision |
|---|---|
| Source of truth | `themes/OneDark-Pro-night-flat.json` in the OneDark-Pro repo |
| Syntax palette | The `classic` text colors (Night Flat uses `vivid: false`) |
| UI palette | Night Flat workbench colors |
| Transparent colors | Blended once onto `#16191d`, result stored with the original in a comment |
| Styles | No bold, no italic. Night Flat is built with `bold: false, italic: false` |
| Flavors | Dark only |
| Options | None. Requiring the module applies the theme |
| Plugin detection | Automatic, by runtimepath check for the plugin's Lua module |
| Colorscheme name | `vim.g.colors_name = 'onedark'` |
| Verification | Screenshots in VSCode and Neovim for Lua, TypeScript, JavaScript, HTML, CSS, Markdown, JSON |

## Scope

Two commits, in this order:

1. Move apple.nvim out: `mv apple.nvim ../apple.nvim`. Move
   `.github/workflows/apple-tests.yml`,
   `docs/superpowers/specs/2026-09-30-apple-colorscheme-design.md` and
   `docs/superpowers/plans/2026-09-30-apple-colorscheme.md` into it. Remove
   the apple wiring from `init.lua`. After this commit Neovim starts with the
   default colorscheme.
2. Add the new theme and wire it in `init.lua`.

## Structure

```
lua/custom/plugins/colorscheme/
  init.lua          -- apply(): clears highlights, sets vim.g.colors_name,
                    --   applies core groups, detects plugins, applies their
                    --   groups, sets terminal colors 0-15, re-checks plugins
                    --   at VimEnter
  palette.lua       -- every color, each with a comment that names its VSCode key
  util.lua          -- has_plugin(), apply(groups)
  groups/
    editor.lua      -- Normal, CursorLine, LineNr, Visual, Pmenu, Search, Diff, ...
    syntax.lua      -- classic Vim groups: Comment, String, Keyword, ...
    treesitter.lua  -- @keyword, @variable, @function, ...
    lsp.lua         -- @lsp.type.*, Diagnostic*
    telescope.lua, blink.lua, gitsigns.lua, which_key.lua, todo_comments.lua,
    mini.lua, fidget.lua, mason.lua, indent_blankline.lua, neo_tree.lua, dap.lua
  tests/
    run.lua         -- nvim --clean -l lua/custom/plugins/colorscheme/tests/run.lua
    helpers.lua
    *_spec.lua
.github/workflows/colorscheme-tests.yml
```

Each group file exports `get(p)` and returns a table
`{ GroupName = { fg = ..., bg = ..., ... } }`. Integration files also export
`detect`, a list of Lua module names that `util.has_plugin()` looks for on the
runtimepath.

The VimEnter re-check exists because kickstart adds plugins after the
colorscheme line in `init.lua`. At VimEnter the module applies the groups of
integrations that were not found during the first run. It does not touch
groups that were already applied.

### init.lua wiring

The apple block (runtimepath prepend, `require('apple').setup`,
`vim.cmd.colorscheme 'apple'`) is replaced by:

```lua
-- [[ Colorscheme ]]
-- One Dark Pro Night Flat, built from the VSCode theme. See lua/custom/plugins/colorscheme/.
require 'custom.plugins.colorscheme'
```

The auto-loader in `lua/custom/plugins/init.lua` only loads `.lua` files, not
folders, so the explicit require is needed.

### Error handling

`apply()` runs each integration file in `pcall`. If one fails, the theme still
loads and the error is reported once with `vim.notify`. Core group files are
not protected: a broken core file must fail loudly.

## Palette

### Syntax colors (`classic` text colors)

| name | hex | used for |
|---|---|---|
| fg | `#abb2bf` | plain text, punctuation |
| red | `#e06c75` | variables, properties, tags, markdown headings |
| orange | `#d19a66` | numbers, constants, attributes |
| yellow | `#e5c07b` | types, classes, namespaces, `this`, `self` |
| green | `#98c379` | strings |
| cyan | `#56b6c2` | operators, escapes, enum members, builtin functions |
| blue | `#61afef` | functions, links |
| purple | `#c678dd` | keywords, storage, `new`, `typeof` |
| comment | `#7f848e` | comments |
| dim | `#5c6370` | markdown quotes, dimmed text |
| error | `#f44747` | invalid tokens |

### UI colors (Night Flat workbench colors)

| name | hex | VSCode key |
|---|---|---|
| bg | `#16191d` | editor.background |
| bg_float | `#1e2227` | editorWidget.background, editorSuggestWidget.background, editorHoverWidget.background |
| bg_input | `#1d1f23` | input.background |
| bg_line | `#2c313c` | editor.lineHighlightBackground |
| bg_select | `#2c313a` | list.activeSelectionBackground, editorSuggestWidget.selectedBackground |
| bg_focus | `#323842` | list.focusBackground, tab.hoverBackground |
| bg_tab | `#23272e` | tab.activeBackground |
| border | `#181a1f` | editorGroup.border, editorSuggestWidget.border, editorHoverWidget.border |
| border_focus | `#3e4452` | focusBorder, panel.border |
| border_sidebar | `#37393d` | sideBar.border |
| line_nr | `#667187` | editorLineNumber.foreground |
| cursor | `#528bff` | editorCursor.foreground |
| guide | `#3b4048` | editorIndentGuide.background1 |
| bracket_match | `#515a6b` | editorBracketMatch.background |
| git_add | `#109868` | editorGutter.addedBackground |
| git_change | `#948b60` | editorGutter.modifiedBackground |
| git_delete | `#9a353d` | editorGutter.deletedBackground |
| diag_error | `#c24038` | editorError.foreground |
| diag_warn | `#d19a66` | editorWarning.foreground |
| diag_info | `#3794ff` | VSCode default for editorInfo.foreground (the theme does not set it) |
| diag_hint | `#7f848e` | judgment call: the comment color. VSCode's hint default is a near-white underline color, wrong for virtual text |
| status_fg | `#9da5b4` | statusBar.foreground |
| inactive_fg | `#6b717d` | titleBar.inactiveForeground |
| tab_fg | `#dcdcdc` | tab.activeForeground |
| list_fg | `#d7dae0` | list.activeSelectionForeground, activityBar.foreground |

### Blended colors

Neovim has no transparency. Each value is blended onto `#16191d` with
`result = alpha * color + (1 - alpha) * bg`, rounded per channel.

| name | VSCode value | VSCode key | stored |
|---|---|---|---|
| selection | `#67769660` | editor.selectionBackground | `#343c4b` |
| search | `#d19a6644` | editor.findMatchBackground | `#483b30` |
| search_other | `#ffffff22` | editor.findMatchHighlightBackground | `#35383b` |
| word_highlight | `#d2e0ff2f` | editor.wordHighlightBackground | `#393e47` |
| diff_add_bg | `#00809b33` | diffEditor.insertedTextBackground | `#122e36` |
| diff_delete_bg | `#ff000033` | VSCode default for diffEditor.removedTextBackground (the theme does not set it) | `#451417` |
| diff_change_bg | `#948b6033` | judgment call: git_change at 20%. VSCode has no changed-line color | `#2f302a` |
| diff_text_bg | `#948b6066` | judgment call: git_change at 40% | `#484738` |
| indent_active | `#c8c8c859` | editorIndentGuide.activeBackground1 | `#545659` |
| whitespace | `#303337` | editorWhitespace.foreground `#ffffff1d`, also tree.indentGuidesStroke | `#303337` |
| ruler | `#abb2bf26` | editorRuler.foreground | `#2c3035` |
| scrollbar | `#4e566660` | scrollbarSlider.background | `#2b3038` |

The blended values above were computed once with a throwaway script; the
implementation stores the results, not the formula.

### Terminal colors

`terminal_color_0` to `terminal_color_15` are the `terminal.ansi*` values of
the theme. They equal the Ghostty theme file:

```
0 #3f4451  1 #e05561  2 #8cc265  3 #d18f52  4 #4aa5f0  5 #c162de  6 #42b3c2  7 #d7dae0
8 #4f5666  9 #ff616e 10 #a5e075 11 #f0a45d 12 #4dc4ff 13 #de73ff 14 #4cd1e0 15 #e6e6e6
```

## Syntax mapping

Rule: no bold, no italic anywhere. Only `undercurl` for diagnostics and
spelling, and `underline` for markup links.

Each tree-sitter capture and LSP semantic token maps to the TextMate scope that
VSCode uses for the same thing. Where VSCode's semantic highlighting changes the
TextMate color, the semantic result wins, because that is what you see in VSCode
for TypeScript and Lua.

### Tree-sitter captures (all languages)

| capture | color | VSCode scope |
|---|---|---|
| `@variable`, `@variable.member`, `@property` | red | variable, variable.other.property |
| `@variable.parameter` | red | variable.parameter (semantic token "parameter" falls back to the `variable` rule) |
| `@variable.builtin` (`this`, `self`, `vim`, `arguments`) | yellow | variable.language |
| `@constant` | orange | constant |
| `@constant.builtin` (`true`, `null`, `nil`) | orange | constant.language |
| `@number`, `@number.float`, `@boolean` | orange | constant.numeric, constant.language |
| `@string`, `@string.special` (template literals) | green | string |
| `@string.escape` | cyan | constant.character.escape |
| `@string.regexp` | red | string.regexp (the last rule in the theme wins) |
| `@character` | green | string |
| `@function`, `@function.call`, `@function.method`, `@function.method.call`, `@constructor` | blue | entity.name.function |
| `@function.builtin` (`require`, `print`, `console.log`) | cyan | support.function |
| `@keyword`, `@keyword.function`, `@keyword.return`, `@keyword.import`, `@keyword.conditional`, `@keyword.repeat`, `@keyword.exception`, `@keyword.type`, `@keyword.modifier` | purple | keyword, storage, keyword.control |
| `@keyword.operator` (`and`, `or`, `not`, `new`, `typeof`, `instanceof`, `in`, `of`) | purple | keyword.operator.word, keyword.operator.new |
| `@operator` (`+ - * / = == < > && !`) | cyan | keyword.operator.arithmetic, .comparison, .logical, .assignment |
| `@punctuation.bracket`, `@punctuation.delimiter` (`( ) { } , . ;`) | fg | punctuation.separator |
| `@punctuation.special` (`${` `}`) | purple | punctuation.definition.template-expression |
| `@type`, `@type.builtin`, `@type.definition` | yellow | entity.name.type, support.type.primitive |
| `@module`, `@namespace` | yellow | entity.name.namespace |
| `@attribute`, `@attribute.builtin` (decorators) | blue | meta.function.decorator |
| `@label` | red | entity.name.label |
| `@comment` | comment | comment |
| `@comment.todo`, `@comment.note`, `@comment.warning`, `@comment.error` | handled by todo-comments | |
| `@tag` (HTML tag names), `@tag.builtin` | red | entity.name.tag |
| `@tag.attribute` | orange | entity.other.attribute-name |
| `@tag.delimiter` (`< > /`) | fg | meta.tag |

### Markdown

| capture | color | VSCode scope |
|---|---|---|
| `@markup.heading` and its `#` marks | red | entity.name.section.markdown, punctuation.definition.heading.markdown |
| `@markup.strong` | orange | markup.bold |
| `@markup.italic` | purple | markup.italic |
| `@markup.raw`, `@markup.raw.block` | green | markup.inline.raw.markdown |
| `@markup.link.label`, `@markup.link` (link text) | blue | string.other.link.title.markdown |
| `@markup.link.url` | purple, underline | markup.underline.link.markdown |
| `@markup.list` (`-`, `1.`) | yellow | punctuation.definition.list.markdown |
| `@markup.quote` | dim | markup.quote.markdown |

### CSS, HTML, JSON

| thing | color | VSCode scope |
|---|---|---|
| CSS property name (`color:`) | fg | support.type.property-name |
| CSS property value keyword (`flex`, `red`) | orange | support.constant.property-value.css |
| CSS tag selector (`div`) | red | entity.name.tag |
| CSS class selector (`.btn`) | orange | entity.other.attribute-name.class.css |
| CSS id selector (`#app`) | blue | entity.other.attribute-name.id |
| CSS pseudo (`:hover`, `::before`) | cyan | entity.other.attribute-name.pseudo-class |
| CSS unit (`px`, `%`) | red | keyword.other.unit |
| CSS number, hex color | orange | constant.numeric |
| CSS `!important` | purple | keyword |
| HTML entity (`&amp;`) | red | constant.character.entity |
| JSON key | red | support.type.property-name.json |
| JSON string value | green | string |
| JSON `true`, `false`, `null` | cyan | constant.language.json |

These need language-specific captures (`@property.css`, `@property.json`,
`@boolean.json`, `@constant.builtin.json`, `@string.special.symbol.css`, ...).
The implementation checks the real capture names with `:Inspect` in Neovim.

### LSP semantic tokens (TypeScript server and lua-language-server)

| token | color | reason |
|---|---|---|
| `@lsp.type.variable`, `.property`, `.parameter` | red | same as tree-sitter |
| `@lsp.typemod.variable.readonly` (`const x`) | yellow | VSCode maps `variable.readonly` to variable.other.constant, which is yellow in this theme |
| `@lsp.typemod.variable.defaultLibrary` (`console`, `Math`, `window`, `vim`) | yellow | semanticTokenColors `variable.defaultLibrary` |
| `@lsp.type.function`, `.method` | blue | entity.name.function |
| `@lsp.typemod.function.defaultLibrary` (`require`, `setTimeout`) | cyan | support.function |
| `@lsp.type.class`, `.interface`, `.type`, `.enum`, `.typeParameter`, `.namespace` | yellow | entity.name.type |
| `@lsp.type.enumMember` | cyan | semanticTokenColors `enumMember` |
| `@lsp.type.keyword` | purple | keyword |
| `@lsp.type.macro` | orange | semanticTokenColors `macro` |
| `@lsp.type.comment` | comment | comment |

### Classic Vim groups

`Comment`, `String`, `Character`, `Number`, `Boolean`, `Float`, `Constant`,
`Identifier`, `Function`, `Statement`, `Keyword`, `Conditional`, `Repeat`,
`Label`, `Operator`, `Exception`, `PreProc`, `Include`, `Define`, `Macro`,
`Type`, `StorageClass`, `Structure`, `Typedef`, `Special`, `SpecialChar`,
`Tag`, `Delimiter`, `SpecialComment`, `Debug`, `Todo`, `Error` get the same
colors as the matching captures above, for file types with no tree-sitter
parser.

### Diagnostics

| group | color | source |
|---|---|---|
| DiagnosticError | diag_error | editorError.foreground |
| DiagnosticWarn | diag_warn | editorWarning.foreground |
| DiagnosticInfo | diag_info | VSCode default |
| DiagnosticHint | diag_hint | comment color (see palette) |
| DiagnosticUnderline* | undercurl, `sp` = the same color | |
| DiagnosticVirtualText* | the same colors, no background | |

### Grammar check results

The VSCode TextMate grammars (built-in Lua, TypeScript, Markdown, CSS, HTML)
settled these points without screenshots:

| thing | VSCode scope | color |
|---|---|---|
| Lua operators `= + == ..` | keyword.operator.lua, no theme rule | fg (`@operator.lua`) |
| Lua `and`, `or`, `not` | keyword.operator.logical.lua | cyan (`@keyword.operator.lua`) |
| Lua `M`, other ALL_CAPS names | variable.other.lua | red (`@constant.lua`) |
| JS/TS ALL_CAPS names | variable.other.constant | yellow (`@constant.typescript`, ...) |
| JS/TS `constructor` keyword | storage.type.ts | purple (`@constructor.typescript`, ...) |
| JS/TS regex flags | keyword.other.ts | purple (`@character.special.typescript`, ...) |
| Markdown `>` quote marker | punctuation.definition.quote under markup.quote | dim |
| Markdown code fences and language name | punctuation.definition.markdown, fenced_code.block.language | fg |
| Markdown `[ ]( )` around links | punctuation.definition.string / metadata | red |
| Markdown emphasis marks `** * \`` | punctuation.definition.bold / italic / raw | the color of the text inside (no `@conceal` group) |
| HTML `=` in attributes | punctuation.separator.key-value | fg |
| HTML `<title>` and `<a>` text | plain text | fg |
| HTML `<!DOCTYPE html>` | entity.name.tag | red |
| CSS `url()`, `calc()`, `var()` | support.function | cyan |
| CSS units `px`, `%` | keyword.other.unit | red |
| CSS hex colors | constant.other.color | orange |
| CSS value keywords `flex`, `red` | support.constant.property-value | orange |
| CSS `.class` selector | entity.other.attribute-name.class | orange (`@type.css`) |
| CSS `#id` selector | entity.other.attribute-name.id | blue (`@constant.css`) |

The base CSS query marks units, hex colors and value keywords as `@string`,
so `after/queries/css/highlights.scm` (with `;; extends`) adds the captures
`@type.unit`, `@constant.color` and `@constant.value`. This file lives at the
config root because tree-sitter loads queries from the runtimepath.

Still open for the screenshot check: the effect of LSP semantic tokens in
VSCode for Lua (`vim`, `string`, operators under lua-language-server) and
TypeScript (enum members, `const` names, `readFile` import).

## Editor groups

| group | value | VSCode source |
|---|---|---|
| Normal, NormalNC | fg on bg | editor.foreground / editor.background |
| CursorLine, CursorColumn, QuickFixLine | bg_line | editor.lineHighlightBackground |
| LineNr | line_nr | editorLineNumber.foreground |
| CursorLineNr | fg | editorLineNumber.activeForeground |
| SignColumn, FoldColumn | bg | |
| Visual, VisualNOS | selection | editor.selectionBackground |
| Search | search_other | editor.findMatchHighlightBackground |
| CurSearch, IncSearch | search | editor.findMatchBackground |
| Substitute | search | |
| MatchParen | bg bracket_match | editorBracketMatch.background |
| Cursor, lCursor, CursorIM | fg bg, bg cursor | editorCursor |
| TermCursor | bg cursor | |
| Whitespace, NonText, EndOfBuffer, SpecialKey | whitespace | editorWhitespace.foreground |
| ColorColumn | ruler | editorRuler.foreground |
| NormalFloat, Pmenu | fg on bg_float | editorWidget.background |
| FloatBorder | border on bg_float | editorSuggestWidget.border |
| FloatTitle | blue on bg_float | |
| PmenuSel | bg_select | editorSuggestWidget.selectedBackground |
| PmenuKind, PmenuExtra | comment on bg_float | |
| PmenuSbar | bg_float | |
| PmenuThumb | scrollbar | scrollbarSlider.background |
| StatusLine | status_fg on bg | statusBar.foreground / background |
| StatusLineNC | inactive_fg on bg | titleBar.inactiveForeground |
| WinSeparator, VertSplit | border | editorGroup.border |
| TabLineSel | tab_fg on bg_tab | tab.activeForeground / activeBackground |
| TabLine, TabLineFill | inactive_fg on bg | tab.inactiveBackground |
| WinBar | fg on bg; WinBarNC inactive_fg | |
| Title | blue | textLink.foreground |
| Directory | blue | |
| DiffAdd | diff_add_bg | diffEditor.insertedTextBackground |
| DiffDelete | diff_delete_bg | VSCode default |
| DiffChange | diff_change_bg | judgment call |
| DiffText | diff_text_bg | judgment call |
| Added, Changed, Removed | green, yellow, red | markup.inserted, markup.changed, markup.deleted |
| SpellBad, SpellCap, SpellLocal, SpellRare | undercurl in diag_error, diag_warn, diag_info, diag_hint | |
| Error | error | |
| ErrorMsg | diag_error | |
| WarningMsg | diag_warn | |
| MoreMsg, Question | green | |
| ModeMsg | fg | |
| Folded | comment on bg_float | |
| Conceal | comment | |
| LineNrAbove, LineNrBelow | line_nr | |
| Underlined | underline | markup.underline |
| WildMenu | bg_select | |
| healthSuccess, healthWarning, healthError | green, diag_warn, diag_error | |

## Plugin integrations

Each integration lives in its own file and is detected automatically with a
runtimepath check for the plugin's Lua module.

- **telescope**: prompt, results and preview use bg_float with border;
  selection bg_select; matching text blue; titles blue. Mirrors the VSCode
  quick-open widget.
- **blink**: menu bg_float, selected bg_select, label match blue, kind icons
  use the syntax colors (function blue, variable red, class yellow, keyword
  purple, constant orange, string green, enum member cyan, module yellow).
  Documentation window the same as NormalFloat.
- **gitsigns**: signs git_add, git_change, git_delete (editorGutter). Inline
  word diff uses DiffAdd and DiffDelete. Blame text uses the comment color.
- **which-key**: keys blue, group purple, description fg, separator comment,
  float bg_float.
- **todo-comments**: TODO blue, NOTE cyan, WARN orange, FIX red, PERF purple,
  HACK orange, TEST green. VSCode One Dark Pro has no TODO colors, so these
  use the syntax colors by meaning.
- **mini**: statusline modes use the syntax colors (normal blue, insert green,
  visual purple, replace red, command orange) on bg_select; cursorword uses
  word_highlight; icons use the syntax colors.
- **fidget**: text comment, title fg, no background.
- **mason**: headers blue on bg_float, installed green, pending orange,
  error red.
- **indent-blankline**: guide `guide`, scope `indent_active`.
- **neo-tree**: background bg (sideBar.background), border border_sidebar
  (sideBar.border), directory names fg, directory icons blue, git status with
  the gitsigns colors, cursor line bg_select, root name fg, indent markers
  whitespace (tree.indentGuidesStroke).
- **dap**: breakpoint red, stopped line bg_line, stopped sign green,
  condition and log signs orange.

## Tests

Run with `nvim --clean -l lua/custom/plugins/colorscheme/tests/run.lua`.
The CI workflow `.github/workflows/colorscheme-tests.yml` runs it on push to
`main` and on pull requests with the stable Neovim release. It replaces
`apple-tests.yml`.

1. Every palette value is `#rrggbb`, lowercase, six hex digits.
2. Every highlight group definition references only `fg`, `bg`, `sp` values
   that exist in the palette or are `NONE`.
3. No group sets `bold` or `italic`.
4. The theme loads in a clean Neovim with no error and sets
   `vim.g.colors_name = 'onedark'`.
5. Every integration file loads and returns a table of groups.
6. Terminal colors 0 to 15 equal the Ghostty theme values.

## Visual verification

After the implementation, one sample file per language (Lua, TypeScript,
JavaScript, HTML, CSS, Markdown, JSON) is prepared in the scratchpad. The user
opens each in VSCode with One Dark Pro Night Flat. The same file is opened in
Neovim. Screenshots are compared. Differences become fixes in the mapping. This
step settles the open items above.

## Out of scope

- A light flavor.
- Options or a `setup()` function.
- A `colors/` entry for `:colorscheme onedark`.
- Publishing the theme as a separate plugin.
