;; extends

; VSCode colors the whole regex literal, including the / delimiters, as
; string.regexp. The base query marks the delimiters as brackets.
(regex
  "/" @string.regexp)
