-- One Dark Pro Night Flat colors.
-- Source: themes/OneDark-Pro-night-flat.json in https://github.com/Binaryify/OneDark-Pro.
-- Each value names its VSCode key. Values with transparency are blended onto
-- the editor background once; the original value is in the comment.
return {
  none = 'NONE',

  -- Syntax: the "classic" text colors of the theme
  fg = '#abb2bf', -- editor.foreground (lightWhite)
  red = '#e06c75', -- coral: variables, properties, tags
  orange = '#d19a66', -- whiskey: numbers, constants, attributes
  yellow = '#e5c07b', -- chalky: types, classes, namespaces
  green = '#98c379', -- green: strings
  cyan = '#56b6c2', -- fountainBlue: operators, escapes, enum members
  blue = '#61afef', -- malibu: functions, links
  purple = '#c678dd', -- purple: keywords
  comment = '#7f848e', -- lightDark: comments
  dim = '#5c6370', -- dark: markdown quotes
  error = '#f44747', -- error: invalid tokens

  -- UI: workbench colors
  bg = '#16191d', -- editor.background, sideBar.background, statusBar.background
  bg_float = '#1e2227', -- editorWidget.background, editorSuggestWidget.background, editorHoverWidget.background
  bg_input = '#1d1f23', -- input.background
  bg_line = '#2c313c', -- editor.lineHighlightBackground
  bg_select = '#2c313a', -- list.activeSelectionBackground, editorSuggestWidget.selectedBackground
  bg_focus = '#323842', -- list.focusBackground, tab.hoverBackground
  bg_tab = '#23272e', -- tab.activeBackground
  border = '#181a1f', -- editorGroup.border, editorSuggestWidget.border, editorHoverWidget.border
  border_focus = '#3e4452', -- focusBorder, panel.border
  border_sidebar = '#37393d', -- sideBar.border
  line_nr = '#667187', -- editorLineNumber.foreground
  cursor = '#528bff', -- editorCursor.foreground
  guide = '#3b4048', -- editorIndentGuide.background1
  bracket_match = '#515a6b', -- editorBracketMatch.background
  git_add = '#109868', -- editorGutter.addedBackground
  git_change = '#948b60', -- editorGutter.modifiedBackground
  git_delete = '#9a353d', -- editorGutter.deletedBackground
  diag_error = '#c24038', -- editorError.foreground
  diag_warn = '#d19a66', -- editorWarning.foreground
  diag_info = '#3794ff', -- VSCode default for editorInfo.foreground; the theme does not set it
  diag_hint = '#7f848e', -- the comment color; VSCode's hint default is an underline color, not for text
  status_fg = '#9da5b4', -- statusBar.foreground
  inactive_fg = '#6b717d', -- titleBar.inactiveForeground
  tab_fg = '#dcdcdc', -- tab.activeForeground
  list_fg = '#d7dae0', -- list.activeSelectionForeground, activityBar.foreground

  -- Blended onto #16191d: result = alpha * color + (1 - alpha) * bg
  selection = '#343c4b', -- editor.selectionBackground #67769660
  search = '#483b30', -- editor.findMatchBackground #d19a6644
  search_other = '#35383b', -- editor.findMatchHighlightBackground #ffffff22
  word_highlight = '#393e47', -- editor.wordHighlightBackground #d2e0ff2f
  diff_add_bg = '#122e36', -- diffEditor.insertedTextBackground #00809b33
  diff_delete_bg = '#451417', -- VSCode default diffEditor.removedTextBackground #ff000033
  diff_change_bg = '#2f302a', -- git_change at 20% (#948b6033); VSCode has no changed-line color
  diff_text_bg = '#484738', -- git_change at 40% (#948b6066)
  indent_active = '#545659', -- editorIndentGuide.activeBackground1 #c8c8c859
  whitespace = '#303337', -- editorWhitespace.foreground #ffffff1d, tree.indentGuidesStroke
  ruler = '#2c3035', -- editorRuler.foreground #abb2bf26
  scrollbar = '#2b3038', -- scrollbarSlider.background #4e566660

  -- terminal.ansi* colors, same as the Ghostty one-dark theme
  terminal = {
    '#3f4451', -- 0 black
    '#e05561', -- 1 red
    '#8cc265', -- 2 green
    '#d18f52', -- 3 yellow
    '#4aa5f0', -- 4 blue
    '#c162de', -- 5 magenta
    '#42b3c2', -- 6 cyan
    '#d7dae0', -- 7 white
    '#4f5666', -- 8 bright black
    '#ff616e', -- 9 bright red
    '#a5e075', -- 10 bright green
    '#f0a45d', -- 11 bright yellow
    '#4dc4ff', -- 12 bright blue
    '#de73ff', -- 13 bright magenta
    '#4cd1e0', -- 14 bright cyan
    '#e6e6e6', -- 15 bright white
  },
}
