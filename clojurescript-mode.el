
;;; clojurescript-mode.el --- Major mode for ClojureScript code

;; Copyright (C) 2011 Luke Amdor, 2012 Andrew Mains
;;
;; Authors: Luke Amdor <luke.amdor@gmail.com>, Andrew Mains <amains12@gmail.com>
;; URL: http://github.com/rubbish/clojurescript-mode
;; Version: 0.1
;; Keywords: languages, lisp, javascript

;; This file is not part of GNU Emacs.

;;; Commentary:

;; Provides an REPL to the ClojureScript language
;; (http://github.com/clojure/clojurescript) using
;; lein cljsbuild.

;; For information on how to start up the REPL correctly see
;; https://github.com/clojure/clojurescript/tree/master/samples/repl
;; and
;; https://github.com/clojure/clojurescript/wiki/The-REPL-and-Evaluation-Environments

;;; License:

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

(require 'clojure-mode)
(require 'subshell-proc)
(require 'comint)

(defcustom clojurescript-repl-type "repl-listen"
  (concat "Which ClojureScript REPL type to use. \n"
          "Valid options are: \"repl-rhino\", \"repl-listen\" and \"repl-launch <command identifier>\".\n"
          "See lein help cljsbuild for details"))

(defvar clojurescript-repl-buffer-name "*cljs*"
  "TODO"
  )

(defun cljs-repl-command ()
  (concat "lein trampoline cljsbuild "
          clojurescript-repl-type))


(defun setup-inf-lisp-buffer ()
  (make-local-variable 'inferior-lisp-buffer)
  (setq inferior-lisp-buffer clojurescript-repl-buffer-name))

(defun inferior-cljs (cmd &optional buffer-name)
  (interactive (list (if current-prefix-arg
                         (read-string "Run lisp: " inferior-lisp-program)
                       inferior-lisp-program)))
  (let ((buffer-name (or buffer-name clojurescript-repl-buffer-name)))
    (if (not (comint-check-proc buffer-name))
        (run-proc cmd buffer-name)
      (inferior-lisp-mode))
    (pop-to-buffer buffer-name)))

(defun de-star (buffer-name)
  (if (string-match "^\\*[^*]*\\*$" buffer-name)
      (substring buffer-name 1 (- (length buffer-name) 1))
    buffer-name))

(defun clojurescript-switch-to-lisp ()
  (interactive)
  (unless (get-buffer-process clojurescript-repl-buffer-name)
    (inferior-cljs (cljs-repl-command)))
  (pop-to-buffer clojurescript-repl-buffer-name))

;; Stolen from clojure-mode.el:
(defconst clojurescript-namespace-name-regex
  (rx line-start
      (zero-or-more whitespace)
      "("
      (zero-or-one (group (regexp "clojure.core/")))
      (zero-or-one (submatch "in-"))
      "ns"
      (zero-or-one "+")
      (one-or-more (any whitespace "\n"))
      (zero-or-more (or (submatch (zero-or-one "#")
                                  "^{"
                                  (zero-or-more (not (any "}")))
                                  "}")
                        (zero-or-more "^:"
                                      (one-or-more (not (any whitespace)))))
                    (one-or-more (any whitespace "\n")))
      ;; why is this here? oh (in-ns 'foo) or (ns+ :user)
      (zero-or-one (any ":'"))
      (group (one-or-more (not (any "()\"" whitespace))) word-end)))

;; Stolen from clojure-mode.el
(defun clojurescript-find-ns ()
  "Find the namespace of the current Clojure buffer."
  (let ((regexp clojurescript-namespace-name-regex))
    (save-restriction
      (save-excursion
        (goto-char (point-min))
        (when (re-search-forward regexp nil t)
          (match-string-no-properties 4))))))

(defun clojurescript-repl-set-ns ()
  (comint-send-string clojurescript-repl-buffer-name
                      (format "(in-ns '%s)\n" (clojurescript-find-ns))))

(defvar clojurescript-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-z") 'clojurescript-switch-to-lisp)
    (define-key map (kbd "C-c M-n") (lambda () (interactive) (clojurescript-repl-set-ns)))
    map))

;;;###autoload
(define-derived-mode clojurescript-mode clojure-mode "ClojureScript"
  "Major mode for ClojureScript"
  (setup-inf-lisp-buffer)
  clojurescript-mode-map
  (add-hook 'inferior-lisp-mode-hook 'inf-lisp-mode-hook nil 't)
  (make-local-variable 'inferior-lisp-program)
  (setq inferior-lisp-program (cljs-repl-command))

  (when (functionp 'slime-mode)
    (slime-mode -1)))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.cljs$" . clojurescript-mode))

(provide 'clojurescript-mode)

;;Hooks

(defun inf-lisp-mode-hook ()
  (let ((cur-buf (current-buffer)))
    (cond ((and (get-buffer clojurescript-repl-buffer-name)
                (not (get-buffer-process clojurescript-repl-buffer-name)))
           (kill-buffer clojurescript-repl-buffer-name)
           (with-current-buffer cur-buf
             (rename-buffer clojurescript-repl-buffer-name)))
          ((not (get-buffer clojurescript-repl-buffer-name))
           (with-current-buffer cur-buf
             (rename-buffer clojurescript-repl-buffer-name)))
          ('t  ;else
           (let ((inf-lisp-proc (get-buffer-process cur-buf)))
             (set-process-buffer inf-lisp-proc nil)
             (kill-process inf-lisp-proc)
             (kill-buffer cur-buf))))))



;;     (if (not (get-buffer clojurescript-repl-buffer-name))

;;                                       ;Else, repl buffer already exists and is active; use it
;;       ))
;; ))


;;If it exists and doesn't have a process -- kill it and rename current
;;If it exists and has a process -- use it
;;If it doesn't exist -- rename current


;;; clojurescript-mode.el ends here
