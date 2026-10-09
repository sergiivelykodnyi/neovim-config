-- Tree-sitter captures. See :help treesitter-highlight-groups.
-- Each capture maps to the TextMate scope VSCode uses for the same thing.
-- Language-specific captures (@property.css, @boolean.json, ...) reproduce
-- the language rules of the VSCode theme.
local M = {}

---@param p table palette
---@return table<string, vim.api.keyset.highlight>
function M.get(p)
  return {
    -- Variables: TextMate "variable" is red
    ['@variable'] = { fg = p.red },
    ['@variable.builtin'] = { fg = p.yellow }, -- variable.language: this, self, vim
    ['@variable.parameter'] = { fg = p.red },
    ['@variable.parameter.builtin'] = { fg = p.yellow },
    ['@variable.member'] = { fg = p.red },
    ['@property'] = { fg = p.red },

    -- Constants
    ['@constant'] = { fg = p.orange },
    ['@constant.builtin'] = { fg = p.orange }, -- constant.language: true, null, nil
    ['@constant.macro'] = { fg = p.orange },

    -- Literals
    ['@number'] = { fg = p.orange },
    ['@number.float'] = { fg = p.orange },
    ['@boolean'] = { fg = p.orange },
    ['@string'] = { fg = p.green },
    ['@string.documentation'] = { fg = p.comment },
    ['@string.regexp'] = { fg = p.cyan }, -- string.regexp: VSCode shows the first matching rule (cyan)
    ['@string.escape'] = { fg = p.cyan }, -- constant.character.escape
    ['@string.special'] = { fg = p.green },
    ['@string.special.symbol'] = { fg = p.cyan },
    ['@string.special.path'] = { fg = p.green },
    ['@string.special.url'] = { fg = p.purple, underline = true },
    ['@character'] = { fg = p.green },
    ['@character.special'] = { fg = p.cyan },

    -- Functions
    ['@function'] = { fg = p.blue },
    ['@function.builtin'] = { fg = p.cyan }, -- support.function
    ['@function.call'] = { fg = p.blue },
    ['@function.macro'] = { fg = p.blue },
    ['@function.method'] = { fg = p.blue },
    ['@function.method.call'] = { fg = p.blue },
    ['@constructor'] = { fg = p.blue },

    -- Keywords
    ['@keyword'] = { fg = p.purple },
    ['@keyword.coroutine'] = { fg = p.purple },
    ['@keyword.function'] = { fg = p.purple },
    ['@keyword.operator'] = { fg = p.purple }, -- keyword.operator.word: and, or, not, new, typeof
    ['@keyword.import'] = { fg = p.purple },
    ['@keyword.type'] = { fg = p.purple },
    ['@keyword.modifier'] = { fg = p.purple },
    ['@keyword.repeat'] = { fg = p.purple },
    ['@keyword.return'] = { fg = p.purple },
    ['@keyword.debug'] = { fg = p.purple },
    ['@keyword.exception'] = { fg = p.purple },
    ['@keyword.conditional'] = { fg = p.purple },
    ['@keyword.conditional.ternary'] = { fg = p.purple },
    ['@keyword.directive'] = { fg = p.purple },
    ['@keyword.directive.define'] = { fg = p.purple },

    -- Operators and punctuation
    ['@operator'] = { fg = p.cyan }, -- keyword.operator.arithmetic, .comparison, .logical, .assignment
    ['@punctuation.delimiter'] = { fg = p.fg },
    ['@punctuation.bracket'] = { fg = p.orange }, -- editorBracketHighlight.foreground1 (bracket pair colorization, level 1)
    ['@punctuation.special'] = { fg = p.purple }, -- template expression ${ }

    -- Types
    ['@type'] = { fg = p.yellow },
    ['@type.builtin'] = { fg = p.yellow },
    ['@type.definition'] = { fg = p.yellow },
    ['@attribute'] = { fg = p.blue }, -- decorators
    ['@attribute.builtin'] = { fg = p.blue },
    ['@module'] = { fg = p.yellow },
    ['@module.builtin'] = { fg = p.yellow },
    ['@namespace'] = { fg = p.yellow },
    ['@label'] = { fg = p.red },

    -- Comments
    ['@comment'] = { fg = p.comment },
    ['@comment.documentation'] = { fg = p.comment },
    ['@comment.error'] = { fg = p.diag_error },
    ['@comment.warning'] = { fg = p.diag_warn },
    ['@comment.todo'] = { fg = p.blue },
    ['@comment.note'] = { fg = p.cyan },

    -- Markup
    ['@markup.strong'] = { fg = p.orange },
    ['@markup.italic'] = { fg = p.purple },
    ['@markup.strikethrough'] = { strikethrough = true },
    ['@markup.underline'] = { underline = true },
    ['@markup.heading'] = { fg = p.red },
    ['@markup.heading.1'] = { fg = p.red },
    ['@markup.heading.2'] = { fg = p.red },
    ['@markup.heading.3'] = { fg = p.red },
    ['@markup.heading.4'] = { fg = p.red },
    ['@markup.heading.5'] = { fg = p.red },
    ['@markup.heading.6'] = { fg = p.red },
    ['@markup.quote'] = { fg = p.dim },
    ['@markup.math'] = { fg = p.blue },
    ['@markup.link'] = { fg = p.blue },
    ['@markup.link.label'] = { fg = p.blue },
    ['@markup.link.url'] = { fg = p.purple, underline = true },
    ['@markup.raw'] = { fg = p.green },
    ['@markup.raw.block'] = { fg = p.green },
    ['@markup.list'] = { fg = p.yellow },
    ['@markup.list.checked'] = { fg = p.green },
    ['@markup.list.unchecked'] = { fg = p.yellow },

    -- Diff
    ['@diff.plus'] = { fg = p.green },
    ['@diff.minus'] = { fg = p.red },
    ['@diff.delta'] = { fg = p.yellow },

    -- Tags (HTML, JSX)
    ['@tag'] = { fg = p.red },
    ['@tag.builtin'] = { fg = p.red },
    ['@tag.attribute'] = { fg = p.orange },
    ['@tag.delimiter'] = { fg = p.fg },

    -- CSS. The base query marks units, hex colors and value keywords as @string;
    -- after/queries/css/highlights.scm adds the captures used below.
    ['@property.css'] = { fg = p.fg }, -- support.type.property-name
    ['@property.scss'] = { fg = p.fg },
    ['@tag.css'] = { fg = p.red }, -- entity.name.tag selector
    ['@tag.scss'] = { fg = p.red },
    ['@type.css'] = { fg = p.orange }, -- .class selector: entity.other.attribute-name.class
    ['@type.scss'] = { fg = p.orange },
    ['@constant.css'] = { fg = p.blue }, -- #id selector: entity.other.attribute-name.id
    ['@constant.scss'] = { fg = p.blue },
    ['@attribute.css'] = { fg = p.cyan }, -- :hover, ::before
    ['@attribute.scss'] = { fg = p.cyan },
    ['@function.css'] = { fg = p.cyan }, -- url(), calc(), var(): support.function
    ['@function.scss'] = { fg = p.cyan },
    ['@keyword.operator.css'] = { fg = p.cyan }, -- and, or, not in @media: keyword.operator.logical
    ['@keyword.import.css'] = { fg = p.purple },
    ['@number.css'] = { fg = p.orange },
    ['@type.unit.css'] = { fg = p.red }, -- px, %, em: keyword.other.unit
    ['@constant.color.css'] = { fg = p.orange }, -- #fff: constant.other.color
    ['@constant.value.css'] = { fg = p.orange }, -- flex, red, none: support.constant.property-value

    -- HTML
    ['@character.special.html'] = { fg = p.red }, -- &amp;
    ['@string.special.url.html'] = { fg = p.green },
    ['@constant.html'] = { fg = p.red }, -- <!DOCTYPE html>: entity.name.tag
    ['@operator.html'] = { fg = p.fg }, -- = in attributes: punctuation.separator.key-value
    ['@markup.heading.html'] = { fg = p.fg }, -- <title> text is plain in VSCode
    ['@markup.link.label.html'] = { fg = p.fg }, -- <a> text is plain in VSCode

    -- JSON
    ['@property.json'] = { fg = p.red },
    ['@boolean.json'] = { fg = p.cyan },
    ['@constant.builtin.json'] = { fg = p.cyan },
    ['@property.jsonc'] = { fg = p.red },
    ['@boolean.jsonc'] = { fg = p.cyan },
    ['@constant.builtin.jsonc'] = { fg = p.cyan },

    -- Markdown. Emphasis marks (@conceal) have no group, so they take the color of their text,
    -- like punctuation.definition.bold / .italic in VSCode.
    ['@punctuation.special.markdown'] = { fg = p.dim }, -- > quote marker: inherits markup.quote
    ['@markup.list.markdown'] = { fg = p.yellow },
    ['@markup.link.markdown_inline'] = { fg = p.fg }, -- [ ]( ) around links have no color in VSCode
    ['@markup.raw.block.markdown'] = { fg = p.fg }, -- fences and language name have no color in VSCode
    ['@label.markdown'] = { fg = p.fg },

    -- JavaScript and TypeScript (also JSX and TSX)
    ['@constant.javascript'] = { fg = p.yellow }, -- SCREAMING_CASE: variable.other.constant
    ['@constant.typescript'] = { fg = p.yellow },
    ['@constant.jsx'] = { fg = p.yellow },
    ['@constant.tsx'] = { fg = p.yellow },
    ['@constructor.javascript'] = { fg = p.purple }, -- the constructor keyword: storage.type
    ['@constructor.typescript'] = { fg = p.purple },
    ['@constructor.jsx'] = { fg = p.purple },
    ['@constructor.tsx'] = { fg = p.purple },
    ['@character.special.javascript'] = { fg = p.cyan }, -- regex flags: same color as the regex in VSCode
    ['@character.special.typescript'] = { fg = p.cyan },
    ['@character.special.jsx'] = { fg = p.cyan },
    ['@character.special.tsx'] = { fg = p.cyan },

    -- Lua: the VSCode grammar gives operators no color and and/or/not the logical color
    ['@operator.lua'] = { fg = p.fg }, -- keyword.operator.lua
    ['@keyword.operator.lua'] = { fg = p.cyan }, -- keyword.operator.logical.lua
    ['@constant.lua'] = { fg = p.red }, -- SCREAMING_CASE is a plain variable in VSCode
    ['@constructor.lua'] = { fg = p.orange }, -- table braces { } are brackets in VSCode
    ['@variable.parameter.luadoc'] = { fg = p.comment }, -- names and types in ---@param keep the comment color
    ['@type.luadoc'] = { fg = p.comment },
    ['@type.builtin.luadoc'] = { fg = p.comment },
  }
end

return M
