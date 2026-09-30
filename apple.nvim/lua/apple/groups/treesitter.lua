-- Highlight groups for treesitter captures (see :help treesitter-highlight-groups).
-- Most captures follow the Xcode-style colors from syntax.lua.
local M = {}

local function style(base, extra) return vim.tbl_extend('force', base, extra or {}) end

---@param p table palette
---@param opts table options
function M.get(p, opts)
  local s = opts.styles or {}
  local keyword = style({ fg = p.pink }, s.keywords)
  local func = style({ fg = p.blue }, s.functions)

  return {
    -- Identifiers
    ['@variable'] = { fg = p.fg },
    ['@variable.builtin'] = { fg = p.purple },
    ['@variable.parameter'] = { fg = p.fg },
    ['@variable.parameter.builtin'] = { fg = p.purple },
    ['@variable.member'] = { fg = p.fg },
    ['@constant'] = { fg = p.yellow },
    ['@constant.builtin'] = { fg = p.yellow },
    ['@constant.macro'] = { fg = p.orange },
    ['@module'] = { fg = p.teal },
    ['@module.builtin'] = { fg = p.purple },
    ['@label'] = { fg = p.pink },

    -- Literals
    ['@string'] = style({ fg = p.red }, s.strings),
    ['@string.documentation'] = { fg = p.comment },
    ['@string.regexp'] = { fg = p.orange },
    ['@string.escape'] = { fg = p.purple },
    ['@string.special'] = { fg = p.purple },
    ['@string.special.symbol'] = { fg = p.yellow },
    ['@string.special.path'] = { fg = p.blue, underline = true },
    ['@string.special.url'] = { fg = p.blue, underline = true },
    ['@character'] = { fg = p.red },
    ['@character.special'] = { fg = p.purple },
    ['@boolean'] = { fg = p.yellow },
    ['@number'] = { fg = p.yellow },
    ['@number.float'] = { fg = p.yellow },

    -- Types
    ['@type'] = { fg = p.teal },
    ['@type.builtin'] = { fg = p.teal },
    ['@type.definition'] = { fg = p.teal },
    ['@attribute'] = { fg = p.orange },
    ['@attribute.builtin'] = { fg = p.orange },
    ['@property'] = { fg = p.fg },

    -- Functions
    ['@function'] = func,
    ['@function.builtin'] = func,
    ['@function.call'] = func,
    ['@function.macro'] = style({ fg = p.orange }, s.functions),
    ['@function.method'] = func,
    ['@function.method.call'] = func,
    ['@constructor'] = { fg = p.teal },
    ['@operator'] = { fg = p.fg },

    -- Keywords
    ['@keyword'] = keyword,
    ['@keyword.coroutine'] = keyword,
    ['@keyword.function'] = keyword,
    ['@keyword.operator'] = keyword,
    ['@keyword.import'] = style({ fg = p.orange }, s.keywords),
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
    ['@punctuation.delimiter'] = { fg = p.fg },
    ['@punctuation.bracket'] = { fg = p.fg },
    ['@punctuation.special'] = { fg = p.purple },

    -- Comments
    ['@comment'] = style({ fg = p.comment }, s.comments),
    ['@comment.documentation'] = style({ fg = p.comment }, s.comments),
    ['@comment.error'] = { fg = p.red, bold = true },
    ['@comment.warning'] = { fg = p.orange, bold = true },
    ['@comment.todo'] = { fg = p.purple, bold = true },
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
    ['@markup.link.label'] = { fg = p.purple },
    ['@markup.link.url'] = { fg = p.blue, underline = true },
    ['@markup.raw'] = { fg = p.red },
    ['@markup.raw.block'] = { fg = p.fg },
    ['@markup.list'] = { fg = p.purple },
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
