;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
(setq user-full-name "Adam Jackman"
      user-mail-address "adam@acjackman.com")


;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
(setq doom-font (font-spec :family "JetBrainsMono Nerd Font" :size 15 :weight 'regular)
      doom-variable-pitch-font (font-spec :family "Source Sans 3" :size 15 :weight 'regular))

;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-one)
(setq doom-theme 'doom-tokyo-night) ;; Dark mode

;; Disable most warnings
(setq warning-minimum-level :emergency)

;; Modeline
(setq doom-modeline-vcs-max-length 20)
(setq doom-modeline-minor-modes nil)
(setq doom-modeline-buffer-state-icon nil)
(setq doom-modeline-major-mode-icon nil)
(setq doom-modeline-buffer-encoding nil)
(setq doom-modeline-buffer-file-name-style 'relative-to-project)
(setq doom-modeline-hud t)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

;; configure  common settings
(setq undo-limit 80000000          ; Raise undo-limit to 80Mb
      evil-want-fine-undo t        ; By default while in insert all changes are one big blob. Be more granular
      auto-save-default nil        ; auto-save with super-save
      truncate-string-ellipsis "…" ; Unicode ellispis are nicer than "...", and also save /precious/ space
      calendar-week-start-day 1    ; Monday is the first day of the week
      );


;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/brain/"
      org-roam-directory "~/brain/"
      org-roam-dailies-directory "journal/"
      +org-roam-open-buffer-on-find-file nil
      org-roam-capture-templates
      '(("d" "default" plain "%?"
         :target (file+head "inbox/%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n#+created: %<%Y-%m-%dT%H:%M:%S%z>\n")
         :unnarrowed t)
        ("o" "obsidian" plain "%?"
         :target (file+head "inbox/%^{ObsidianId}-${slug}.org" "#+title: ${title}\n#+obsidianid: %^{ObsidianId}\n#+created: %^{Created}\n")
         :unnarrowed t)
        ("e" "effort" plain (file "~/.config/doom/roam-templates/effort.org")
         :target (file+head "inbox/%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}")
         :unnarrowed t)
        ("p" "person" plain (file "~/.config/doom/roam-templates/person.org")
         :target (file+head "e/person/%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}")
         :unnarrowed t)
        ("b" "book" plain (file "~/.config/doom/roam-templates/book.org")
         :target (file+head "e/book/%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}")
         :unnarrowed t)
        )

      org-roam-dailies-capture-templates
      '(("d" "default" plain "%?"
         :if-new (file+head "%<%Y-%m-%d>.org" "#+title: %<%Y-%m-%d>\n* Calendar\n:PROPERTIES:\n:VISIBILITY: children\n:END:\n* Log\n:PROPERTIES:\n:VISIBILITY: children\n:END:\n* Tasks\n:PROPERTIES:\n:VISIBILITY: children\n:END:\n")
         :unnarrowed t
         :immediate-finish t))
)

;; Disable org mode tag inheritance for better org-roam compatibility
(setq! org-use-tag-inheritance nil)


(defun org-roam-dailies-capture- (time &optional goto templates)
  (let ((org-roam-directory (expand-file-name org-roam-dailies-directory org-roam-directory))
        (org-roam-dailies-directory "./"))
    (org-roam-capture- :goto (when goto '(4))
                       :node (org-roam-node-create)
                       :templates (or templates org-roam-dailies-capture-templates)
                       :props (list :override-default-time time)))
  (when goto (run-hooks 'org-roam-dailies-find-file-hook)))

;; Jump to common files
(defun my/org-roam-open-root-node (keys)
  (interactive "P")
  (org-roam-node-open (org-roam-node-from-id "1d110b64-2969-477f-a368-cd13bfc8eb95")))

(defun my/org-roam-dailies-goto-today (keys)
  (interactive "P")
  (org-roam-dailies-capture-today t "d"))

(map! "C-M-s-SPC" #'my/org-roam-dailies-goto-today
      "<C-M-s-return>" #'my/org-roam-open-root-node)

;; Quick capture to dailies file
(defun org-roam-dailies-capture-today-log (keys)
  (interactive "P")
  (org-roam-dailies-capture- (current-time) nil
                             '(("d" nil entry "** %<%H:%M>: %?"
                                :if-new (file+olp "%<%Y-%m-%d>.org" ("Log"))
                                ))
                             ))

(defun org-roam-dailies-capture-today-meeting (keys)
  (interactive "P")
  (org-roam-dailies-capture- (current-time) nil
                             '(("i" nil entry "** %<%H:%M>: %?"
                                :if-new (file+olp "%<%Y-%m-%d>.org" ("Calendar"))
                                :clock-in t
                                :clock-keep t
                                :jump-to-captured t))
                             ))

(defun org-roam-dailies-capture-today-interrupt (keys)
  (interactive "P")
  (org-roam-dailies-capture- (current-time) nil
                             '(("i" nil entry "** Interrupt %<%H:%M>: %?"
                                :if-new (file+olp "%<%Y-%m-%d>.org" ("Log"))
                                :clock-in t :clock-resume t))
                             ))

(defun org-roam-dailies-capture-today-task (keys)
  (interactive "P")
  (org-roam-dailies-capture- (current-time) nil
                             '(("d" nil entry "* TODO %?"
                                :if-new (file+olp "%<%Y-%m-%d>.org" ("Tasks"))))
                             ))

;; Log an item to daily file
(map! :leader
      (:prefix-map ("l" . "Log")
       :desc "Daily Log" "l" #'org-roam-dailies-capture-today-log
       :desc "Interrupt" "i" #'org-roam-dailies-capture-today-interrupt
       :desc "Meeting" "m" #'org-roam-dailies-capture-today-meeting
       :desc "Daily Task" "t" #'org-roam-dailies-capture-today-task))


(defun my/brain-sync ()
  (interactive)
  (save-some-buffers 'no-confirm (lambda ()
                                   (cond
                                    ((and buffer-file-name (string-prefix-p org-roam-directory buffer-file-name)))
                                    ((and buffer-file-name (derived-mode-p 'org-mode))))))
  (let (
        (shell-command-buffer-name "*Brain Sync*")
        (max-mini-window-height .90))
    (shell-command "~/.bin/push-brain")
    ;; (switch-to-buffer "Brain Sync")
    (org-roam-db-sync)
    ))

(map! :leader "n r p" #'my/brain-sync)

;; ;; DevonThink Links
;; (defun org-devonthink-item-open (uid)
;;   "Open the given uid, which is a reference to an item in Devonthink"
;;   (shell-command (concat "open \"x-devonthink-item:" uid "\"")))
;; (org-add-link-type "x-devonthink-item" 'org-devonthink-item-open)

;; ;; Slack Links
;; (defun org-slack-open (url)
;;   "Open the given uid, which is a reference to an item in Devonthink"
;;   (shell-command (concat "open \"slack:" url "\"")))
;; (org-add-link-type "slack" 'org-slack-open)


;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look up their documentation).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
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
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.

(use-package! iterm
  :commands (iterm-send-text
             iterm-cd))


(map! "<C-s-return>" #'iterm-send-text
      "C-s-/" #'iterm-cd)

(map! :leader
      (:prefix-map ("g" . "git")
                   (:prefix ("w" . "worktree")
                    :desc "Worktree dispatch" "w" #'magit-worktree
                    :desc "branch and worktree" "c" #'magit-worktree-branch
                    :desc "Delete" "k" #'magit-worktree-delete
                    :desc "Visit" "g" #'magit-worktree-status
                    )
                   (:prefix ("c" . "create")
                    :desc "branch and worktree" "w" #'magit-worktree-branch
                    :desc "worktree" "W" #'magit-worktree-checkout
                    )))

(defun add-list-to-list (dst src)
  "Similar to `add-to-list', but accepts a list as 2nd argument"
  (set dst
       (append (eval dst) src)))

(after! lsp-mode
  (add-to-list 'lsp-file-watch-ignored-directories "[/\\\\]\\.mypy_cache\\'")
  (add-to-list 'lsp-file-watch-ignored-directories "[/\\\\]\\__pycache__\\'")
  (add-to-list 'lsp-file-watch-ignored-directories "[/\\\\]\\.nox\\'")
  (setq lsp-enable-indentation nil))

;; TODO figure out howto make this work
;; (after! forge
;;   (setq forge-buffer-draft-p t))

(use-package! hcl-mode)
(use-package! rego-mode)

(use-package! dired-quick-sort)
(after! dired-quick-sort
  (dired-quick-sort-setup))



;; TODO: get ligatures working
;; (after! org
;;   (set-ligatures! 'org-mode
;;     :src_block     "»"
;;     :src_block_end "«")
;;   )

(map! :map terraform-mode-map
      :localleader
      :desc "validate" "v" (cmd! (compile (format "%s validate" +terraform-runner) t))
      :desc "init-upgrade" "u" (cmd! (compile (format "%s init -upgrade" +terraform-runner) t))
      :desc "format" "f" (cmd! (compile (format "%s fmt -recursive" +terraform-runner) t)))

;; TODO: Setup ruff as the python linter
;; (setq flycheck-python-flake8-executable "flake8heavened")

;; from https://git.0xee.eu/0xee/emacs-config/commit/bc2011419c9d4f5c119c9e347ba85c8203fb11e5
(defun projectile-find-file-or-magit (&optional arg)
  "Jump to a project's file using completion.
With a prefix ARG invalidates the cache first."
  (interactive "P")
  (projectile-maybe-invalidate-cache arg)
  (let ((file (projectile-completing-read "Find file: "
                                          (append (list "*magit*") (projectile-current-project-files))
                                          :initial-input "*magit*")))
    (if (string= file "*magit*")
        (magit-status (projectile-project-root))
      (progn (find-file (expand-file-name file (projectile-project-root)))
             (run-hooks 'projectile-find-file-hook))
      )
    )
  )


;; Pull up version control status instead of picking a file when switching projects
;; https://www.reddit.com/r/emacs/comments/2qthru/comment/cnac0j9/
(setq! +workspaces-switch-project-function #'projectile-find-file-or-magit)


;; doom's `persp-mode' activation disables uniquify, b/c it says it breaks it.
;; It doesn't cause big enough problems for me to worry about it, so we override
;; the override. `persp-mode' is activated in the `doom-init-ui-hook', so we add
;; another hook at the end of the list of hooks to set our uniquify values.
;; https://www.reddit.com/r/DoomEmacs/comments/shp6ez/comment/hv5lmat/
(add-hook! 'doom-init-ui-hook
           :append ;; ensure it gets added to the end.
           #'(lambda () (require 'uniquify) (setq uniquify-buffer-name-style 'forward)))


;; TODO Setup a local machine directory
;; (defun load-directory (directory)
;;   "Load recursively all `.el' files in DIRECTORY."
;;   (dolist (element (directory-files-and-attributes directory nil nil nil))
;;     (let* ((path (car element))
;;            (fullpath (concat directory "/" path))
;;            (isdir (car (cdr element)))
;;            (ignore-dir (or (string= path ".") (string= path ".."))))
;;       (cond
;;        ((and (eq isdir t) (not ignore-dir))
;;         (load-directory fullpath))
;;        ((and (eq isdir nil) (string= (substring path -3) ".el"))
;;         (load (file-name-sans-extension fullpath)))))))


;; (setq! 'doom-machine-dir (fullpath (concat doom-private-dir "/../doom-machine/config.el")) )
;; (if (file-exists-p doom-machine-dir) (load))
