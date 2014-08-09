A mode for clojurescript which supports using a clojurescript repl
(through use of the excellent lein-cljsbuild.)

The mode derives from clojure-mode, so pretty much everything should
be the same as there. The only exception is that instead of starting
inferior-lisp processes in "\*inferior-lisp\*", it starts them in
"\*cljs\*". All repl evaluation functions from clojure mode should
work.

* `C-c z` jumps to the REPL buffer (creating a REPL process as
  necessary).
* `C-c M-n` switches the REPL namespace to that of the current file.
* `C-c C-e` evaluates the preceding s-expression.

Requires subshell-proc and clojure-mode. Load it into your init.el
with something like:

````elisp
(require-package 'subshell-proc)
(require 'clojurescript-mode)

(add-to-list 'auto-mode-alist '("\.cljs$" . clojurescript-mode))
```

Assumes you've got both lein and cljsbuild already set up (if not, see
https://github.com/emezeske/lein-cljsbuild).

"Forked" from http://marmalade-repo.org/packages/clojurescript-mode.

