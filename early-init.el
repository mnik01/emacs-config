;;; early-init.el --- Pre-GUI/package Emacs config -*- lexical-binding: t; -*-

;; Raise GC threshold during startup for faster load
(setq gc-cons-threshold (* 100 1024 1024))  ; 100 MB

;; Disable UI chrome early to prevent white-flash flicker
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars . nil) default-frame-alist)
(push '(horizontal-scroll-bars . nil) default-frame-alist)

;; Dark background matching Monokai Pro — prevents white flash on startup
(push '(background-color . "#2d2a2e") default-frame-alist)
(push '(foreground-color . "#fcfcfa") default-frame-alist)

;; Initial frame size — 80 columns x 24 lines
(push '(width . 80) default-frame-alist)
(push '(height . 24) default-frame-alist)
(push '(width . 80) initial-frame-alist)
(push '(height . 24) initial-frame-alist)

;; Pixel-wise frame resizing (normal app behavior)
(setq frame-resize-pixelwise t)

;; Don't resize frame at startup based on font
(setq frame-inhibit-implied-resize t)

;; Suppress native-compilation warnings
(setq native-comp-async-report-warnings-errors 'silent)

;; Don't load site-start.el
(setq site-run-file nil)

;; Prevent package.el from loading packages before init.el
(setq package-enable-at-startup nil)

;;; early-init.el ends here
