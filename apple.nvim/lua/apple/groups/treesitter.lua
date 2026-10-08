-- Highlight groups for treesitter captures (see :help treesitter-highlight-groups).
-- Most captures follow the colors from syntax.lua (One Dark style).
-- Every variable, parameter and property is red. Built-ins like `this`,
-- `self` and `vim` are yellow. Delimiters are cyan.
local M = {}

local function style(base, extra) return vim.tbl_extend('force', base, extra or {}) end

---@param p table palette
---@param opts table options
function M.get(p, opts)
  local s = opts.styles or {}
  local keyword = style({ fg = p.purple }, s.keywords)
  local func = style({ fg = p.blue }, s.functions)

  return {
    -- Identifiers
    ['@variable'] = { fg = p.red },
    ['@variable.builtin'] = { fg = p.yellow },
    ['@variable.parameter'] = { fg = p.red },
    ['@variable.parameter.builtin'] = { fg = p.yellow },
    ['@variable.member'] = { fg = p.red },
    ['@constant'] = { fg = p.orange },
    ['@constant.builtin'] = { fg = p.orange },
    ['@constant.macro'] = { fg = p.orange },
    ['@module'] = { fg = p.teal },
    ['@module.builtin'] = { fg = p.yellow },
    ['@label'] = { fg = p.purple },

    -- Literals
    ['@string'] = style({ fg = p.green }, s.strings),
    ['@string.documentation'] = { fg = p.comment },
    ['@string.regexp'] = { fg = p.orange },
    ['@string.escape'] = { fg = p.pink },
    ['@string.special'] = { fg = p.pink },
    ['@string.special.symbol'] = { fg = p.orange },
    ['@string.special.path'] = { fg = p.blue, underline = true },
    ['@string.special.url'] = { fg = p.blue, underline = true },
    ['@character'] = { fg = p.green },
    ['@character.special'] = { fg = p.pink },
    ['@boolean'] = { fg = p.orange },
    ['@number'] = { fg = p.orange },
    ['@number.float'] = { fg = p.orange },

    -- Types
    ['@type'] = { fg = p.yellow },
    ['@type.builtin'] = { fg = p.yellow },
    ['@type.definition'] = { fg = p.yellow },
    ['@attribute'] = { fg = p.orange },
    ['@attribute.builtin'] = { fg = p.orange },
    ['@property'] = { fg = p.red },

    -- Functions
    ['@function'] = func,
    ['@function.builtin'] = func,
    ['@function.call'] = func,
    ['@function.macro'] = style({ fg = p.orange }, s.functions),
    ['@function.method'] = func,
    ['@function.method.call'] = func,
    ['@constructor'] = { fg = p.yellow },
    ['@operator'] = { fg = p.fg },

    -- Keywords
    ['@keyword'] = keyword,
    ['@keyword.coroutine'] = keyword,
    ['@keyword.function'] = keyword,
    ['@keyword.operator'] = keyword,
    ['@keyword.import'] = keyword,
    ['@keyword.type'] = keyword,
    ['@keyword.modifier'] = keyword,
    ['@keyword.repeat'] = keyword,
    ['@keyword.return'] = keyword,
    ['@keyword.debug'] = keyword,
    ['@keyword.exception'] = keyword,
    ['@keyword.conditional'] = keyword,
    ['@keyword.conditional.ternary'] = { fg = p.fg },
    ['@keyword.directive'] = style({ fg = p.orange }, s.keywords),
    ['@keyword.directive.define'] = style({ fg = p.orange }, s.keywords),

    -- Punctuation
    ['@punctuation.delimiter'] = { fg = p.cyan },
    ['@punctuation.bracket'] = { fg = p.fg },
    ['@punctuation.special'] = { fg = p.pink },

    -- Comments
    ['@comment'] = style({ fg = p.comment }, s.comments),
    ['@comment.documentation'] = style({ fg = p.comment }, s.comments),
    ['@comment.error'] = { fg = p.red, bold = true },
    ['@comment.warning'] = { fg = p.orange, bold = true },
    ['@comment.todo'] = { fg = p.pink, bold = true },
    ['@comment.note'] = { fg = p.blue, bold = true },

    -- Markup (markdown, help, ...)
    ['@markup.strong'] = { bold = true },
    ['@markup.italic'] = { italic = true },
    ['@markup.strikethrough'] = { strikethrough = true },
    ['@markup.underline'] = { underline = true },
    ['@markup.heading'] = { fg = p.blue, bold = true },
    ['@markup.heading.1'] = { fg = p.blue, bold = true },
    ['@markup.heading.2'] = { fg = p.teal, bold = true },
    ['@markup.heading.3'] = { fg = p.green, bold = true },
    ['@markup.heading.4'] = { fg = p.yellow, bold = true },
    ['@markup.heading.5'] = { fg = p.orange, bold = true },
    ['@markup.heading.6'] = { fg = p.pink, bold = true },
    ['@markup.quote'] = { fg = p.comment },
    ['@markup.math'] = { fg = p.yellow },
    ['@markup.link'] = { fg = p.blue },
    ['@markup.link.label'] = { fg = p.pink },
    ['@markup.link.url'] = { fg = p.blue, underline = true },
    ['@markup.raw'] = { fg = p.red },
    ['@markup.raw.block'] = { fg = p.fg },
    ['@markup.list'] = { fg = p.pink },
    ['@markup.list.checked'] = { fg = p.green },
    ['@markup.list.unchecked'] = { fg = p.comment },

    -- Diff and tags
    ['@diff.plus'] = { fg = p.green },
    ['@diff.minus'] = { fg = p.red },
    ['@diff.delta'] = { fg = p.blue },
    ['@tag'] = { fg = p.blue },
    ['@tag.builtin'] = { fg = p.blue },
    ['@tag.attribute'] = { fg = p.teal },
    ['@tag.delimiter'] = { fg = p.fg },
  }
end

return M
