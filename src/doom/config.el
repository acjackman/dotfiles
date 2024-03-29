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
      doom-variable-pitch-font (font-spec :family "Source Sans 3" :size 15 :weight 'regular))

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
;; (setq doom-theme 'doom-one) ;; Dooms's default
(setq doom-theme 'doom-tokyo-night) ;; Dark mode
;; (setq doom-theme 'doom-solarized-light) ;; Light mode

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

;; Define your custom doom-modeline
;; (doom-modeline-def-modeline 'my-simple-line
;;   '(bar matches buffer-info remote-host buffer-position parrot selection-info)
;;   '(misc-info minor-modes input-method buffer-encoding major-mode process vcs checker))

;; ;; Set default mode-line
;; (add-hook 'doom-modeline-mode-hook
;;           (lambda ()
;;             (doom-modeline-set-modeline 'my-simple-line 'default)))



;; Org Templates

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
         :immediate-finish t)))


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

(defun my/org-roam-open-root-node (keys)
  (interactive "P")
  (org-roam-node-open (org-roam-node-from-id "1d110b64-2969-477f-a368-cd13bfc8eb95")))



(defun my/org-roam-dailies-goto-today (keys)
  (interactive "P")
  (org-roam-dailies-capture-today t "d"))

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



;; Capture immediate (Source: https://systemcrafters.net/build-a-second-brain-in-emacs/5-org-roam-hacks/#fast-note-insertion-for-a-smoother-writing-flow)
(defun org-roam-node-insert-immediate (arg &rest args)
  (interactive "P")
  (let ((args (cons arg args))
        (org-roam-capture-templates (list (append (car org-roam-capture-templates)
                                                  '(:immediate-finish t)))))
    (apply #'org-roam-node-insert args)))

(map! :leader "n r I" #'org-roam-node-insert-immediate)

;; edt
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


;; (defun my/org-roam-project-finalize-hook ()
;;   "Adds the captured project file to `org-agenda-files' if the
;; capture was not aborted."
;;   ;; Remove the hook since it was added temporarily
;;   (remove-hook 'org-capture-after-finalize-hook #'my/org-roam-project-finalize-hook)

;;   ;; Add project file to the agenda list if the capture was confirmed
;;   (unless org-note-abort
;;     (with-current-buffer (org-capture-get :buffer)
;;       (add-to-list 'org-agenda-files (buffer-file-name)))))


;; From https://systemcrafters.net/build-a-second-brain-in-emacs/5-org-roam-hacks/
(defun my/org-roam-filter-by-tag (tag-name)
  (lambda (node)
    (member tag-name (org-roam-node-tags node))))

(defun my/org-roam-filter-by-missing-tag (tag-name)
  (lambda (node)
    (-not (member tag-name (org-roam-node-tags node)))))

(defun my/org-roam-filter-by-folder (folder-name)
  (lambda (node)
    (string-prefix-p folder-name (org-roam-node-file node))))

(defun clerk/org-roam-filter-by-folder (folder-name)
  (lambda (node)
    (string-prefix-p (concat (expand-file-name org-roam-directory) folder-name) (org-roam-node-file node))))

(defun clerk/org-roam-find-node (filter templates)
  (org-roam-node-find nil nil filter nil :templates templates))

(defun clerk/org-roam-find-resource (dir &optional template-file)
  (message ";;;; dir %S" dir )
  (clerk/org-roam-find-node
   (clerk/org-roam-filter-by-folder dir)
   '(("d" "default" plain (if template-file '(file (concat doom-user-dir "roam-templates/" template-file)) "%?")
      :target (file+head "inbox/%<%Y%m%d%H%M%S>-${slug}.org"  "#+title: ${title}\n#+created: %<%Y-%m-%dT%H:%M:%S%z>\n")
      :unnarrowed t))
   )
  )

(defun clerk/org-roam-insert-node (filter templates)
  (org-roam-node-insert filter :templates templates))

(defun clerk/org-roam-insert-resource (dir &optional template-file)
  (clerk/org-roam-insert-node
   (clerk/org-roma-filter-by-folder dir)
   '(("d" "default" plain (if template-file '(file (concat doom-user-dir "roam-templates/" template-file)) "%?")
      :target (file+head "inbox/%<%Y%m%d%H%M%S>-${slug}.org"  "#+title: ${title}\n#+created: %<%Y-%m-%dT%H:%M:%S%z>\n")
      :unnarrowed t
      :immediate-finish t))
   )
  )


(defun my/org-roam-find-role ()
  (interactive)
  (org-roam-node-find
   nil
   nil
   (my/org-roam-filter-by-tag "Role")))

;; (defun my/org-roam-find-project ()
;;   (interactive)
;;   ;; Add the project file to the agenda after capture is finished
;;   ;; (add-hook 'org-capture-after-finalize-hook #'my/org-roam-project-finalize-hook)
;;   ;; Select a project file to open, creating it if necessary
;;   (org-roam-node-find
;;    nil
;;    nil
;;    (my/org-roam-filter-by-tag "Project")
;;    nil
;;    :templates
;;    '(("p" "project" plain (file "~/.doom.d/roam-templates/project.org")
;;            :target (file+head "%<%Y%m%d%H%M%S>-${slug}.org")
;;            :unnarrowed t))))


(map! :leader
      :prefix ("N" . "Find Note")

      ;; :desc "Node" "n" #'org-roam-node-find
      (:prefix ("r" . "roles")
               (:prefix ("m" . "moov")
                :desc "role" "r" (lambda () (interactive) (org-open-file (expand-file-name org-roam-directory "r/mv/moov-role.org")))
                :desc "efforts" "e" (lambda () (interactive) (clerk/org-roam-find-resource "r/mv/efforts/" "effort.org"))
                )
               (:prefix ("n" . "nerd")
                :desc "role" "r" (lambda () (interactive) (org-open-file (expand-file-name org-roam-directory "r/nerd/nerd-role.org")))
                :desc "efforts" "e" (lambda () (interactive) (clerk/org-roam-find-resource "r/nerd/efforts/" "effort.org"))
                )
               (:prefix ("l" . "life")
                :desc "role" "r" (lambda () (interactive) (org-open-file (expand-file-name org-roam-directory "r/life/life-role.org")))
                :desc "efforts" "e" (lambda () (interactive) (clerk/org-roam-find-resource "r/life/efforts/" "effort.org"))
                )
               (:prefix ("v" . "verisage")
                :desc "role" "r" (lambda () (interactive) (org-open-file (expand-file-name org-roam-directory "r/vs/vs-role.org")))
                :desc "efforts" "e" (lambda () (interactive) (clerk/org-roam-find-resource "r/vs/efforts/" "effort.org"))
                )
               (:prefix ("f" . "fulcrum")
                :desc "role" "r" (lambda () (interactive) (org-open-file (expand-file-name org-roam-directory "r/fl/vs-role.org")))
                :desc "efforts" "e" (lambda () (interactive) (clerk/org-roam-find-resource "r/fl/efforts/" "effort.org"))
                )
               )
      ;; :desc "Question" "q" #'my/org-roam-find-question

      (:prefix ("SPC" . "Find entity node")
       :desc "article" "a" (lambda () (interactive) (clerk/org-roam-find-resource "e/article/" "article.org"))
       :desc "book" "b" (lambda () (interactive) (clerk/org-roam-find-resource "e/book/" "book.org"))
       :desc "clipping" "c" (lambda () (interactive) (clerk/org-roam-find-resource "e/clipping/" "clipping.org"))
       ;; :desc "music" "m" (lambda () (interactive) (clerk/org-roam-find-resource "e/music/" "music.org"))
       :desc "movie" "m" (lambda () (interactive) (clerk/org-roam-find-resource "e/movie/" "movie.org"))
       :desc "person" "p" (lambda () (interactive) (clerk/org-roam-find-resource "e/person/" "person.org"))
       :desc "tv-show" "t" (lambda () (interactive) (clerk/org-roam-find-resource "e/tv-show/" "tv-show.org"))
       :desc "video-game" "v" (lambda () (interactive) (clerk/org-roam-find-resource "e/video-game/" "video-game.org"))
       )
      )

;; (map! :leader
;;   :prefix ("C-n" . "Link note")
;;   (:prefix ("r" . "roles")
;;     (:prefix ("w" . "moov")
;;       :desc "role" "r" (lambda () (interactive) (org-open-file (concat (expand-file-name org-roam-directory) "role/mv/moov-role.org")))
;;       :desc "projects" "p" (lambda () (interactive) (clerk/org-roam-insert-resource "role/mv/projects/" "project.org"))
;;     )
;;     (:prefix ("n" . "nerd")
;;       :desc "role" "r" (lambda () (interactive) (org-open-file (concat (expand-file-name org-roam-directory) "role/nerd/nerd-role.org")))
;;       :desc "projects" "p" (lambda () (interactive) (clerk/org-roam-insert-resource "role/nerd/projects/" "project.org"))
;;     )
;;     (:prefix ("l" . "life")
;;       :desc "role" "r" (lambda () (interactive) (org-open-file (concat (expand-file-name org-roam-directory) "role/life/life-role.org")))
;;       :desc "projects" "p" (lambda () (interactive) (clerk/org-roam-insert-resource "role/life/projects/" "project.org"))
;;     )
;;     (:prefix ("v" . "verisage")
;;       :desc "role" "r" (lambda () (interactive) (org-open-file (concat (expand-file-name org-roam-directory) "role/vs/vs-role.org")))
;;       :desc "projects" "p" (lambda () (interactive) (clerk/org-roam-insert-resource "role/vs/projects/" "project.org"))
;;     )
;;   )
;;   :desc "Person" "p" (lambda () (interactive) (clerk/org-roam-insert-resorce "cards/people/"))

;;   (:prefix ("SPC" . "Reference node")
;;     :desc "book" "b" (lambda () (interactive) (clerk/org-roam-insert-resource "r/book/" "book.org"))
;;     :desc "video-game" "g" (lambda () (interactive) (clerk/org-roam-insert-resource "r/video-game/"))
;;     :desc "movie" "m" (lambda () (interactive) (clerk/org-roam-insert-resource "r/movie/"))
;;     :desc "tv-show" "t" (lambda () (interactive) (clerk/org-roam-insert-resource "r/tv-show/"))
;;   )
;; )


(map! "C-M-s-SPC" #'my/org-roam-dailies-goto-today
      "<C-M-s-return>" #'my/org-roam-open-root-node)


;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

(setq undo-limit 80000000                         ; Raise undo-limit to 80Mb
      evil-want-fine-undo t                       ; By default while in insert all changes are one big blob. Be more granular
      auto-save-default nil                       ; auto-save with super-save
      truncate-string-ellipsis "…"                ; Unicode ellispis are nicer than "...", and also save /precious/ space
      );

(setq frame-title-format
      '(""
        (:eval
         (if (s-contains-p org-roam-directory (or buffer-file-name ""))
             (replace-regexp-in-string
              ".*/[0-9]*-?" "☰ "
              (subst-char-in-string ?_ ?  buffer-file-name))
           "%b"))
        (:eval
         (let ((project-name (projectile-project-name)))
           (unless (string= "-" project-name)
             (format (if (buffer-modified-p)  " ◉ %s" "  ●  %s") project-name))))))

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

;;  (defface org-link-roam
;;    '((t :underline t))
;;    "Face for Org-Mode links starting with id:."
;;    :group 'org-faces)

;; (org-link-set-parameters
;;   "id"
;;   :face 'org-link-roam)

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
  (add-to-list 'lsp-file-watch-ignored-directories "[/\\\\]\\__pycache__\\'")
  (add-to-list 'lsp-file-watch-ignored-directories "[/\\\\]\\.nox\\'")
  (setq lsp-enable-indentation nil))

(after! forge
  (setq forge-buffer-draft-p t))




(setq calendar-week-start-day 1)

;;(use-package! dirvish
;;  :config
;;  (dirvish-override-dired-mode 1)
;;)


(use-package! elpher)

(use-package! nov)

(use-package! hcl-mode)
(use-package! rego-mode)

(use-package! mermaid-mode)

(use-package! dired-quick-sort)
(after! dired-quick-sort
  (dired-quick-sort-setup))


(use-package! dash-at-point)

(setq! org-superstar-special-todo-items nil)
(setq! org-superstar-headline-bullets-list '("⬣" "⬡" "⁜" "➙" "▷" "▣" "◈"))

(after! org
  (set-ligatures! 'org-mode
    :src_block     "»"
    :src_block_end "«")
  )




(setq confirm-kill-emacs nil)

;; DevonThink Links
(org-add-link-type "x-devonthink-item" 'org-devonthink-item-open)

(defun org-devonthink-item-open (uid)
  "Open the given uid, which is a reference to an item in Devonthink"
  (shell-command (concat "open \"x-devonthink-item:" uid "\"")))

(org-add-link-type "slack" 'org-slack-open)

(defun org-slack-open (url)
  "Open the given uid, which is a reference to an item in Devonthink"
  (shell-command (concat "open \"slack:" url "\"")))

(map! :map terraform-mode-map
      :localleader
      :desc "validate" "v" (cmd! (compile (format "%s validate" +terraform-runner) t))
      :desc "init-upgrade" "u" (cmd! (compile (format "%s init -upgrade" +terraform-runner) t))
      :desc "format" "f" (cmd! (compile (format "%s fmt -recursive" +terraform-runner) t)))


(defun formatted-copy ()
  "Export region to Rich Text, and copy it to the clipboard."
  (interactive)
  (save-window-excursion
    (let* ((buf (org-export-to-buffer 'html "*Formatted Copy*" nil nil t t))
           (html (with-current-buffer buf (buffer-string))))
      (with-current-buffer buf
        (shell-command-on-region
         (point-min)
         (point-max)
         "textutil -stdin -format html -convert rtf -stdout | pbcopy"))
      (kill-buffer buf))))

(map!
 :after org
 :map org-mode-map

 :localleader
 "E" #'formatted-copy
 )

(setq flycheck-python-flake8-executable "flake8heavened")

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

(add-to-list 'doom-detect-indentation-excluded-modes 'org-mode)

(org-indent-mode -1)
