local t = require 'helpers'
local config = require 'apple.config'

t.test('defaults: auto flavor, plain comments, bold keywords', function()
  t.eq('auto', config.defaults.flavor)
  t.eq({}, config.defaults.styles.comments)
  t.eq({ bold = true }, config.defaults.styles.keywords)
  t.eq({}, config.defaults.styles.functions)
  t.eq({}, config.defaults.styles.strings)
  t.eq({}, config.defaults.integrations)
  t.eq(nil, config.defaults.on_highlights)
end)

t.test('options start equal to defaults', function() t.eq(config.defaults, config.options) end)

t.test('extend merges user options over defaults', function()
  local o = config.extend { flavor = 'light', integrations = { telescope = false } }
  t.eq('light', o.flavor)
  t.eq(false, o.integrations.telescope)
  t.eq({ bold = true }, o.styles.keywords, 'untouched style keeps default')
  t.eq(o, config.options, 'result is stored')
end)

t.test('extend resets to defaults each call', function()
  config.extend { flavor = 'light' }
  local o = config.extend {}
  t.eq('auto', o.flavor)
end)

-- Review focus 2: a style table replaces the default, so {} removes bold.
t.test('a style table replaces the default instead of merging', function()
  local o = config.extend { styles = { keywords = {}, comments = { italic = true } } }
  t.eq({}, o.styles.keywords)
  t.eq({ italic = true }, o.styles.comments)
  t.eq({}, o.styles.functions, 'other styles keep defaults')
end)

t.test('extend does not change defaults', function()
  config.extend { styles = { keywords = { italic = true } }, integrations = { mini = false } }
  t.eq({ bold = true }, config.defaults.styles.keywords)
  t.eq({}, config.defaults.integrations)
end)

t.test('extend with nil is the same as empty', function() t.eq(config.defaults, config.extend()) end)

config.extend()
