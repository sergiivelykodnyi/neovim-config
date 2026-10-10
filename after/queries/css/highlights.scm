;; extends

; One Dark Pro colors units, hex colors and value keywords differently from
; strings. The base query marks all of them as @string. These captures come
; last, so they win. The colorscheme defines @type.unit.css, @constant.color.css
; and @constant.value.css.
(unit) @type.unit

(color_value) @constant.color

((plain_value) @constant.value
  (#not-lua-match? @constant.value "^[-][-]"))
