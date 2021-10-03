;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets.
(setq user-full-name "Adam Jackman"
      user-mail-address "adam@acjackman.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom. Here
;; are the three important ones:
;;
;; + `doom-font'
;; + `doom-variable-pitch-font'
;; + `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;;
;; They all accept either a font-spec, font string ("Input Mono-12"), or xlfd
;; font string. You generally only need these two:
(setq doom-font (font-spec :family "JetBrainsMono Nerd Font" :size 15 :weight 'regular)
     doom-variable-pitch-font (font-spec :family "Source Sans Pro" :size 15 :weight 'regular))

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-one)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/brain/"
      org-roam-directory "~/brain/"
      org-roam-dailies-directory "journal/"
      +org-roam-open-buffer-on-find-file nil
      org-roam-capture-templates
       '(("d" "default" plain
          "%?"
          :if-new (file+head "%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n#+created: %U\n")
          :unnarrowed t)
         ("p" "project" plain  (file "~/.doom.d/roam-templates/project.org")
          :if-new (file+head "%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n#+created: %U\n#+category: ${title}\n#+filetags: Project\n")
          :unnarrowed t)
        )
      org-roam-dailies-capture-templates
           ' (("d" "default" entry "* %<%H:%M>: %?"
               :if-new (file+head "%<%Y-%m-%d>.org" "#+title: %<%Y-%m-%d>\n")))
)

;;(map! :map org-mode-map "SPC n n" nil)
(map! :leader "X" nil)
(map! :leader "X" #'org-roam-dailies-capture-today)


(map! "C-M-s-SPC" #'org-roam-dailies-goto-today
  "<C-M-s-return>" #'org-roam-dailies-goto-today  ;; TODO: this should goto README or a root index
  )

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)


(use-package! iterm
  :commands (iterm-send-text
             iterm-cd)
  )

(map! "<C-s-return>" #'iterm-send-text
      "C-s-/" #'iterm-cd)

;; Here are some additional functions/macros that could help you configure Doom:
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.

(defun add-list-to-list (dst src)
  "Similar to `add-to-list', but accepts a list as 2nd argument"
  (set dst
    (append (eval dst) src)))

(after! lsp-mode
       (add-to-list 'lsp-file-watch-ignored-directories "[/\\\\]\\.mypy_cache\\'")
       (add-to-list 'lsp-file-watch-ignored-directories "[/\\\\]\\.nox\\'")
)
