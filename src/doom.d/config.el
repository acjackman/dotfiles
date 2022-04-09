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
       '(("d" "default" plain "%?"
          :target (file+head "%<%Y%m%d%H%M%S>-${slug}.org" "${title}\n#+created: %<Y-%m-%dT%H:%M:%S%z>\n")
           :unnarrowed t)
         ("o" "obsidian" plain "%?"
          :target (file+head "%^{ObsidianId}-${slug}.org" "${title}\n#+obsidianid: %^{ObsidianId}\n#+created: %^{Created}\n")
          :unnarrowed t)
         ("p" "project" plain (file "~/.doom.d/roam-templates/project.org")
          :target (file+head "%<%Y%m%d%H%M%S>-${slug}.org" "${title}")
           :unnarrowed t)
         ("b" "book" plain (file "~/.doom.d/roam-templates/book.org")
          :target (file+head "r/book/%<%Y%m%d%H%M%S>-${slug}.org" "${title}")
          :unnarrowed t)
        )
      org-roam-dailies-capture-templates
        '(("d" "default" entry "** %<%H:%M>: %?"
           :heading "Log"
           :if-new (file+head+olp "%<%Y-%m-%d>.org" "%<%Y-%m-%d>\n* Log\n:PROPERTIES:\n:VISIBILITY: children\n:END:\n" ("Log")))
        )
  )

;;(map! :map org-mode-map "SPC n n" nil)
(map! :leader "X" nil)
(map! :leader "x" nil)
(map! :leader "x" #'org-roam-dailies-capture-today)


;; Capture immediate (Source: https://systemcrafters.net/build-a-second-brain-in-emacs/5-org-roam-hacks/#fast-note-insertion-for-a-smoother-writing-flow)
(defun org-roam-node-insert-immediate (arg &rest args)
  (interactive "P")
  (let ((args (cons arg args))
        (org-roam-capture-templates (list (append (car org-roam-capture-templates)
                                                  '(:immediate-finish t)))))
    (apply #'org-roam-node-insert args)))

(map! :leader "n r I" #'org-roam-node-insert-immediate)



(map! "C-M-s-SPC" #'org-roam-dailies-goto-today
  "<C-M-s-return>" #'org-roam-dailies-goto-today  ;; TODO: this should goto README or a root index
  )

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

(use-package! super-save
  :config
  (super-save-mode +1)
)
(setq super-save-auto-save-when-idle t)
(setq auto-save-default nil)

(use-package! iterm
  :commands (iterm-send-text
             iterm-cd)
  )

(map! "<C-s-return>" #'iterm-send-text
      "C-s-/" #'iterm-cd)


;; https://www.eigenbahn.com/2021/09/15/org-roam#fn:4
;; (defun prf/org/file-path-org-p (f)
;;   "Return t if file path F corresponds to an org file."
;;   (let ((cleaned-f (s-chop-suffixes '("gpg" "bak") f)))
;;     (equal (f-ext cleaned-f) "org")))

;; (defvar prf/org/index-file-exclude-regexp "\\.gpg\\'")

;; (defun prf/org/file-path-indexable-p (f)
;;   "Return t if file path F corresponds to an indexable org file."
;;   (and (prf/org/file-path-org-p f)
;;        (f-descendant-of? f org-roam-directory)
;;     (not (string-match-p prf/org/index-file-exclude-regexp f))
;;   )
;; )

;; (defun prf/org-roam/rescan ()
;;   "Force rescan of whole `prf/dir/notes'."
;;   (interactive)
;;   (prf/org/index-rescan-all)
;;   (org-roam-db-sync))

;; (defun prf/org/index-rescan-all ()
;;   "Populate `org-id-locations' by rescaning recursively all files in `prf/dir/notes'."
;;   (interactive)
;;   (let ((buffs-snapshot (buffer-list)))
;;     (org-id-update-id-locations
;;     (f-files org-roam-directory #'prf/org/file-path-indexable-p t))
;;     ;; NB: `org-id-update-id-locations' opens all matching files, we close them after processing
;;     (mapc #'kill-buffer
;;       (-difference (buffer-list) buffs-snapshot))))


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


(setq calendar-week-start-day 1)

(use-package! dirvish
  :config
  (dirvish-override-dired-mode 1)
)
