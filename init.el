;;; init.el --- Sublime Text 4-like Emacs config -*- lexical-binding: t; -*-

;; External dependencies:
;;   npm install -g typescript-language-server typescript
;;   npm install -g vscode-langservers-extracted
;;   sudo apt install clangd ripgrep clang-format
;;   npm install -g prettier
;; After first launch: M-x nerd-icons-install-fonts

;; ============================================================================
;; 1. Package System
;; ============================================================================

(require 'package)
(setq package-archives
      '(("melpa"  . "https://melpa.org/packages/")
        ("gnu"    . "https://elpa.gnu.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/nongnu/")))
(package-initialize)

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(eval-when-compile (require 'use-package))
(setq use-package-always-ensure t)

;; ============================================================================
;; 2. General Settings (Sublime behavior)
;; ============================================================================

;; CUA mode — Ctrl+C/V/X/Z standard keys
(cua-mode 1)

;; C-x: cut region, or cut whole line if no selection (Sublime behavior)
;; Override CUA's C-x prefix mechanism via emulation-mode-map-alists
(defun my/cut-line-or-region ()
  "Cut region if active, otherwise cut the whole line."
  (interactive)
  (if (use-region-p)
      (kill-region (region-beginning) (region-end))
    (kill-whole-line)))

(defvar my/sublime-override-map (make-sparse-keymap))
(define-key my/sublime-override-map (kbd "C-x") #'my/cut-line-or-region)
(defvar my/sublime-override-mode t)
(push `((my/sublime-override-mode . ,my/sublime-override-map))
      emulation-mode-map-alists)

;; Bar cursor like Sublime
(setq-default cursor-type 'bar)

;; Typing replaces selected text
(delete-selection-mode 1)

;; Smooth pixel scrolling
(pixel-scroll-precision-mode 1)

;; Auto-close brackets/quotes
(electric-pair-mode 1)

;; Highlight matching parens
(show-paren-mode 1)

;; Line numbers in all programming/text buffers
(global-display-line-numbers-mode 1)

;; Highlight current line
(global-hl-line-mode 1)

;; No backup/lockfiles
(setq make-backup-files nil
      auto-save-default nil
      create-lockfiles nil)

;; UTF-8 everywhere
(set-default-coding-systems 'utf-8)
(prefer-coding-system 'utf-8)

;; Remember cursor position in files
(save-place-mode 1)

;; Track recent files
(recentf-mode 1)
(setq recentf-max-saved-items 100)

;; Delete trailing whitespace on save
(add-hook 'before-save-hook #'delete-trailing-whitespace)

;; 4-space indentation by default, no tabs
(setq-default indent-tabs-mode nil
              tab-width 4)

;; y/n instead of yes/no
(setq use-short-answers t)

;; Don't ring the bell
(setq ring-bell-function #'ignore)

;; Scroll one line at a time
(setq scroll-conservatively 101
      scroll-margin 2)

;; Disable startup screen
(setq inhibit-startup-screen t
      initial-scratch-message nil)

;; Suppress *Warnings* buffer from popping up
(setq warning-minimum-level :error)

;; Start with a clean empty buffer (acts like "untitled" file)
(setq initial-major-mode 'fundamental-mode)
(setq initial-buffer-choice t)  ; *scratch* buffer

;; Automatically refresh buffers when files change on disk
(global-auto-revert-mode 1)

;; Ruler line at column 80 (visible regardless of zoom)
(setq-default display-fill-column-indicator-column 80)
(global-display-fill-column-indicator-mode 1)
;; Make ruler visible on Monokai Pro background
(with-eval-after-load 'doom-themes
  (set-face-attribute 'fill-column-indicator nil :foreground "#5b595c"))

;; Word wrap at window edge (like Sublime default)
(setq-default word-wrap t)
(setq-default truncate-lines nil)

;; ============================================================================
;; 3. Font
;; ============================================================================

(defun my/set-font ()
  "Set the best available monospace font."
  (let ((font (cond
               ((find-font (font-spec :name "JetBrains Mono")) "JetBrains Mono")
               ((find-font (font-spec :name "Fira Code")) "Fira Code")
               ((find-font (font-spec :name "Ubuntu Mono")) "Ubuntu Mono")
               ((find-font (font-spec :name "DejaVu Sans Mono")) "DejaVu Sans Mono")
               (t nil))))
    (when font
      (set-face-attribute 'default nil :font font :height 120))))

(if (daemonp)
    (add-hook 'after-make-frame-functions
              (lambda (frame)
                (with-selected-frame frame (my/set-font))))
  (my/set-font))

;; ============================================================================
;; 4. Theme — doom-monokai-pro
;; ============================================================================

(use-package doom-themes
  :config
  (load-theme 'doom-monokai-pro t)
  (doom-themes-org-config)
  (doom-themes-treemacs-config))

;; ============================================================================
;; 5. Modeline — doom-modeline + nerd-icons
;; ============================================================================

(use-package nerd-icons)

(use-package doom-modeline
  :hook (after-init . doom-modeline-mode)
  :config
  (setq doom-modeline-height 28
        doom-modeline-bar-width 4
        doom-modeline-icon (display-graphic-p)
        doom-modeline-unicode-fallback t
        doom-modeline-buffer-file-name-style 'truncate-upto-project))

;; ============================================================================
;; 6. Tabs — centaur-tabs
;; ============================================================================

(use-package centaur-tabs
  :hook (after-init . centaur-tabs-mode)
  :config
  (setq centaur-tabs-style "bar"
        centaur-tabs-height 32
        centaur-tabs-set-icons t
        centaur-tabs-set-modified-marker t
        centaur-tabs-modified-marker "●"
        centaur-tabs-show-new-tab-button nil
        centaur-tabs-set-bar 'under
        x-underline-at-descent-line t)
  (centaur-tabs-group-by-projectile-project)

  ;; Hide internal/special buffers from tabs — only show real files
  (defun my/centaur-tabs-hide-tab (buffer)
    "Hide BUFFER from tabs if it's a special/internal buffer."
    (let ((name (buffer-name buffer)))
      (or (string-prefix-p "*" name)
          (string-prefix-p " " name))))
  (setq centaur-tabs-hide-tab-function #'my/centaur-tabs-hide-tab)
  :bind
  (("C-<tab>"     . centaur-tabs-forward)
   ("C-<iso-lefttab>" . centaur-tabs-backward)
   ("C-S-<tab>"   . centaur-tabs-backward)
   ("C-w"         . centaur-tabs--kill-this-buffer-dont-ask)))  ; Sublime: C-w closes tab

;; Reopen closed tab (C-S-t) — track closed file paths
(defvar my/closed-file-history nil "List of recently closed file paths.")

(defun my/track-closed-file ()
  "Save the file path before a buffer is killed."
  (when buffer-file-name
    (push buffer-file-name my/closed-file-history)))
(add-hook 'kill-buffer-hook #'my/track-closed-file)

(defun my/reopen-closed-tab ()
  "Reopen the most recently closed file tab."
  (interactive)
  (if my/closed-file-history
      (let ((file (pop my/closed-file-history)))
        (if (file-exists-p file)
            (find-file file)
          (my/reopen-closed-tab)))  ; skip deleted files
    (message "No closed tabs to reopen")))
(global-set-key (kbd "C-S-t") #'my/reopen-closed-tab)

;; ============================================================================
;; 7. File Sidebar — treemacs
;; ============================================================================

(use-package treemacs
  :bind ("C-b" . treemacs)  ; Sublime: C-b toggle sidebar
  :config
  (setq treemacs-width 30
        treemacs-is-never-other-window nil
        treemacs-show-hidden-files t
        treemacs-display-in-side-window nil)  ; avoid side-window conflicts
  (treemacs-follow-mode 1)
  (treemacs-filewatch-mode 1)
  (treemacs-git-mode 'deferred))

(use-package treemacs-nerd-icons
  :after treemacs
  :config (treemacs-load-theme "nerd-icons"))

(use-package treemacs-projectile
  :after (treemacs projectile))

;; ============================================================================
;; 8. Completion Framework — vertico + orderless + consult + marginalia
;; ============================================================================

(use-package vertico
  :init (vertico-mode 1)
  :config
  (setq vertico-count 15
        vertico-cycle t))

(use-package orderless
  :config
  (setq completion-styles '(orderless basic)
        completion-category-overrides '((file (styles partial-completion)))))

(use-package marginalia
  :init (marginalia-mode 1))

(use-package consult
  :bind
  (("C-S-p" . execute-extended-command) ; Sublime: C-S-p command palette
   ("C-f"   . consult-line)       ; Sublime: C-f search in buffer
   ("C-g"   . consult-goto-line)  ; Sublime: C-g goto line
   ("C-r"   . consult-recent-file)) ; Sublime: C-r recent files
  :config
  (setq consult-find-args "find . -not -path '*/.*' -not -path '*/node_modules/*'"))

;; C-p / C-S-f: always search in project dir (set by C-o), not .emacs.d
(defun my/find-file ()
  "Find file in project directory."
  (interactive)
  (consult-find (or my/project-dir default-directory)))

(defun my/search-project ()
  "Ripgrep search in project directory."
  (interactive)
  (consult-ripgrep (or my/project-dir default-directory)))

(global-set-key (kbd "C-p") #'my/find-file)
(global-set-key (kbd "C-S-f") #'my/search-project)

;; ============================================================================
;; 9. In-Buffer Completion — corfu + cape
;; ============================================================================

(use-package corfu
  :init (global-corfu-mode 1)
  :config
  (setq corfu-auto t
        corfu-auto-delay 0.1
        corfu-auto-prefix 2
        corfu-cycle t
        corfu-preselect 'prompt)
  :bind (:map corfu-map
         ("TAB"     . corfu-next)
         ([tab]     . corfu-next)
         ("S-TAB"   . corfu-previous)
         ([backtab] . corfu-previous)))

(use-package cape
  :init
  (add-to-list 'completion-at-point-functions #'cape-dabbrev)
  (add-to-list 'completion-at-point-functions #'cape-file)
  (add-to-list 'completion-at-point-functions #'cape-keyword))

;; ============================================================================
;; 10. Project Management — projectile
;; ============================================================================

(use-package projectile
  :init (projectile-mode 1)
  :config
  (setq projectile-project-search-path '("~/projects/" "~/src/")
        projectile-sort-order 'recently-active))

;; ============================================================================
;; 11. Multiple Cursors
;; ============================================================================

(use-package multiple-cursors
  :bind
  (("C-d"   . mc/mark-next-like-this)     ; Sublime: C-d select next occurrence
   ("C-S-l" . mc/edit-lines)              ; Sublime: C-S-l cursors on selected lines
   ("M-<mouse-1>" . mc/add-cursor-on-click))) ; Sublime: Alt+Click add cursor

;; ============================================================================
;; 12. Sublime Keybindings
;; ============================================================================

(use-package move-text
  :config (move-text-default-bindings))  ; Alt+Up/Down to move lines

;; ---- Sublime/VSCode-style selection behavior ----
;; Arrow without Shift + active selection:
;;   Right/Down → deselect, cursor to END of selection
;;   Left/Up    → deselect, cursor to BEGINNING of selection
;; Shift+Arrow: start or extend selection
;; No selection + arrow: normal movement

;; Select all — cursor at end of buffer
(defun my/select-all ()
  "Select entire buffer with cursor at end (Sublime behavior)."
  (interactive)
  (push-mark (point-min) nil t)
  (goto-char (point-max)))
(global-set-key (kbd "C-a") #'my/select-all)

;; Plain arrow keys — deselect-aware
(defun my/arrow-right ()
  (interactive)
  (if (use-region-p)
      (progn (goto-char (region-end)) (deactivate-mark))
    (right-char 1)))

(defun my/arrow-left ()
  (interactive)
  (if (use-region-p)
      (progn (goto-char (region-beginning)) (deactivate-mark))
    (left-char 1)))

(defun my/arrow-down ()
  (interactive)
  (if (use-region-p)
      (progn (goto-char (region-end)) (deactivate-mark))
    (next-line 1)))

(defun my/arrow-up ()
  (interactive)
  (if (use-region-p)
      (progn (goto-char (region-beginning)) (deactivate-mark))
    (previous-line 1)))

(global-set-key (kbd "<right>") #'my/arrow-right)
(global-set-key (kbd "<left>")  #'my/arrow-left)
(global-set-key (kbd "<down>")  #'my/arrow-down)
(global-set-key (kbd "<up>")    #'my/arrow-up)

;; Shift+arrow keys — start or extend selection explicitly
(defun my/shift-right ()
  (interactive)
  (unless (use-region-p) (set-mark (point)))
  (forward-char 1))

(defun my/shift-left ()
  (interactive)
  (unless (use-region-p) (set-mark (point)))
  (backward-char 1))

(defun my/shift-down ()
  (interactive)
  (unless (use-region-p) (set-mark (point)))
  (next-line 1))

(defun my/shift-up ()
  (interactive)
  (unless (use-region-p) (set-mark (point)))
  (previous-line 1))

(global-set-key (kbd "S-<right>") #'my/shift-right)
(global-set-key (kbd "S-<left>")  #'my/shift-left)
(global-set-key (kbd "S-<down>")  #'my/shift-down)
(global-set-key (kbd "S-<up>")    #'my/shift-up)

;; Save
(global-set-key (kbd "C-s") #'save-buffer)

;; Save As
(global-set-key (kbd "C-S-s") #'write-file)

;; Redo (CUA already provides C-z for undo)
(global-set-key (kbd "C-S-z") #'undo-redo)

;; Toggle comment
(global-set-key (kbd "C-/") #'comment-line)

;; Delete line
(global-set-key (kbd "C-S-k") #'kill-whole-line)

;; Select line (extends on repeat)
(defun my/select-line ()
  "Select the current line. Extend selection on repeat."
  (interactive)
  (if (use-region-p)
      (progn (forward-line 1) (end-of-line))
    (beginning-of-line)
    (set-mark (point))
    (end-of-line)))
(global-set-key (kbd "C-l") #'my/select-line)

;; Duplicate line
(defun my/duplicate-line ()
  "Duplicate the current line below."
  (interactive)
  (let ((col (current-column)))
    (save-excursion
      (move-beginning-of-line 1)
      (let ((line (buffer-substring (point) (line-end-position))))
        (end-of-line)
        (newline)
        (insert line)))
    (forward-line 1)
    (move-to-column col)))
(global-set-key (kbd "C-S-d") #'my/duplicate-line)

;; New line below/above
(defun my/open-line-below ()
  "Open a new line below, move cursor there."
  (interactive)
  (end-of-line)
  (newline-and-indent))
(global-set-key (kbd "C-<return>") #'my/open-line-below)

(defun my/open-line-above ()
  "Open a new line above, move cursor there."
  (interactive)
  (beginning-of-line)
  (newline)
  (forward-line -1)
  (indent-according-to-mode))
(global-set-key (kbd "C-S-<return>") #'my/open-line-above)

;; Query replace (C-h is now replace; F1 for help)
(global-set-key (kbd "C-h") #'query-replace)
(global-set-key (kbd "<f1>") #'help-command)

;; Escape as keyboard-quit (replaces C-g which is now goto-line)
(global-set-key (kbd "<escape>") #'keyboard-escape-quit)

;; Fullscreen
(global-set-key (kbd "<f11>") #'toggle-frame-fullscreen)

;; Quit Emacs (C-x prefix is gone since C-x is now cut)
(global-set-key (kbd "C-q") #'save-buffers-kill-terminal)

;; Unbind Emacs-only keys that don't exist in Sublime and cause confusion
(global-unset-key (kbd "C-k"))  ; was: kill-line
;; C-o: open folder as working directory (Sublime: Open Folder)
(defvar my/project-dir nil "Current project working directory.")

(defun my/open-folder ()
  "Choose a folder and set it as the working project directory.
Updates treemacs sidebar if visible."
  (interactive)
  (let ((dir (expand-file-name (read-directory-name "Open folder: "))))
    (setq my/project-dir dir)
    (setq default-directory dir)
    ;; Update treemacs to show the new directory
    (when (fboundp 'treemacs--show-single-project)
      (let ((name (file-name-nondirectory (directory-file-name dir))))
        (treemacs--show-single-project (treemacs-canonical-path dir) name)))
    (message "Project directory: %s" dir)))
(global-set-key (kbd "C-o") #'my/open-folder)
(global-unset-key (kbd "C-t"))  ; was: transpose-chars
(global-unset-key (kbd "C-y"))  ; was: yank (C-v is paste via CUA)
(global-unset-key (kbd "C-u"))  ; was: universal-argument

;; ============================================================================
;; 13. which-key for discoverability
;; ============================================================================

(use-package which-key
  :init (which-key-mode 1)
  :config
  (setq which-key-idle-delay 0.5
        which-key-separator " → "))

;; ============================================================================
;; 14. Tree-sitter
;; ============================================================================

(use-package treesit-auto
  :config
  (setq treesit-auto-install 'prompt)
  (setq treesit-auto-langs '(c cpp css html javascript json typescript tsx))
  (treesit-auto-add-to-auto-mode-alist '(c cpp css html javascript json typescript tsx))
  (global-treesit-auto-mode 1))

;; ============================================================================
;; 15. Web Development
;; ============================================================================

(use-package web-mode
  :mode ("\\.html\\'" "\\.jsx\\'" "\\.tsx\\'" "\\.vue\\'" "\\.svelte\\'")
  :config
  (setq web-mode-markup-indent-offset 2
        web-mode-css-indent-offset 2
        web-mode-code-indent-offset 2
        web-mode-enable-auto-pairing t
        web-mode-enable-css-colorization t
        web-mode-enable-current-element-highlight t))

(use-package emmet-mode
  :hook ((web-mode . emmet-mode)
         (css-mode . emmet-mode)
         (css-ts-mode . emmet-mode)))

(use-package typescript-mode
  :mode "\\.ts\\'"
  :config
  (setq typescript-indent-level 2))

;; JS 2-space indent
(setq js-indent-level 2)

;; ============================================================================
;; 16. C Development
;; ============================================================================

(add-hook 'c-ts-mode-hook
          (lambda ()
            (setq c-ts-mode-indent-offset 4
                  c-ts-mode-indent-style 'k&r)))

(add-hook 'c-mode-hook
          (lambda ()
            (setq c-basic-offset 4)
            (c-set-style "k&r")))

;; ============================================================================
;; 17. LSP — eglot (built-in)
;; ============================================================================

(use-package eglot
  :ensure nil  ; built-in
  :hook ((c-mode          . eglot-ensure)
         (c-ts-mode       . eglot-ensure)
         (js-mode         . eglot-ensure)
         (js-ts-mode      . eglot-ensure)
         (typescript-mode . eglot-ensure)
         (typescript-ts-mode . eglot-ensure)
         (tsx-ts-mode     . eglot-ensure)
         (web-mode        . eglot-ensure)
         (css-mode        . eglot-ensure)
         (css-ts-mode     . eglot-ensure))
  :config
  ;; Connect web-mode to typescript-language-server
  (add-to-list 'eglot-server-programs
               '(web-mode . ("typescript-language-server" "--stdio")))
  (setq eglot-autoshutdown t
        eglot-events-buffer-size 0))  ; disable events log for performance

;; ============================================================================
;; 18. Auto-formatting — apheleia
;; ============================================================================

(use-package apheleia
  :hook (after-init . apheleia-global-mode))

;; ============================================================================
;; 19. Git — magit
;; ============================================================================

(use-package magit
  :bind ("C-S-g" . magit-status))

;; ============================================================================
;; 20. Terminal panel (C-j toggle, like VSCode)
;; ============================================================================

(defvar my/terminal-buffer-name "*terminal*")
(defvar my/terminal-window nil)

(defun my/toggle-terminal ()
  "Toggle a terminal panel at the bottom. Hides without killing."
  (interactive)
  (cond
   ;; Terminal window is visible — hide it
   ((and my/terminal-window (window-live-p my/terminal-window))
    (delete-window my/terminal-window)
    (setq my/terminal-window nil))
   ;; Terminal buffer exists but hidden — show it
   ((get-buffer my/terminal-buffer-name)
    (setq my/terminal-window
          (display-buffer-in-side-window
           (get-buffer my/terminal-buffer-name)
           '((side . bottom) (slot . 0) (window-height . 0.3))))
    (select-window my/terminal-window))
   ;; No terminal — create one
   (t
    (let ((buf (save-window-excursion
                 (ansi-term (or (getenv "SHELL") "/bin/bash")
                            "terminal")
                 (current-buffer))))
      (setq my/terminal-window
            (display-buffer-in-side-window
             buf '((side . bottom) (slot . 0) (window-height . 0.3))))
      (select-window my/terminal-window)))))

(global-set-key (kbd "C-j") #'my/toggle-terminal)

;; Make C-j work inside the terminal too (term-mode intercepts all C- keys)
(add-hook 'term-mode-hook
          (lambda ()
            (define-key term-raw-map (kbd "C-j") #'my/toggle-terminal)))

;; ============================================================================
;; 21. Rainbow delimiters
;; ============================================================================

(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

;; ============================================================================
;; 21. Finalization
;; ============================================================================

;; Restore GC threshold and ensure clean single-window startup
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 16 1024 1024))  ; 16 MB
            ;; Kill unwanted buffers and ensure single window
            (dolist (buf '("*Warnings*" "*Compile-Log*"))
              (when (get-buffer buf) (kill-buffer buf)))
            (delete-other-windows)
            (message "Emacs loaded in %.2f seconds with %d garbage collections."
                     (float-time (time-subtract after-init-time before-init-time))
                     gcs-done)))

;;; init.el ends here
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages
   '(rainbow-delimiters magit apheleia typescript-mode emmet-mode web-mode treesit-auto which-key move-text multiple-cursors cape corfu consult marginalia orderless vertico treemacs-projectile treemacs-nerd-icons treemacs centaur-tabs doom-modeline doom-themes nerd-icons)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
