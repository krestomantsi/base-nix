(setq user-full-name "Nick Lamprinidis"
      user-mail-address "nlampri@gmail.com")

;;(setq doom-font (font-spec :family "FiraCode Nerd Font" :size 18 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "FiraCode" :size 18))

;;(setq doom-theme 'doom-one)
(setq doom-theme 'catppuccin)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type 'relative)
(global-display-line-numbers-mode)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")

;; changing pdf colors
;;(add-hook 'pdf-tools-enabled-hook 'pdf-view-themed-minor-mode)
;; force pdf-view instead of ubuntu pdf

(after! org
  (add-to-list 'org-file-apps '("\\.pdf\\'" . emacs)))
;; making odt docs default format into docx
(setq org-odt-preferred-output-format "docx")

;;align csv with csv-mode
(after! csv-mode
  (setq csv-separators '("," ";" "|" " "))
  (setq csv-align-style 'auto))

;; dired better details
(after! dired
  (setq dired-hide-details-mode nil))

;; accept completion from copilot and fallback to company
(after! copilot
  (use-package! copilot
    :hook (prog-mode . copilot-mode)
    :bind (:map copilot-completion-map
                ("<tab>" . 'copilot-accept-completion)
                ("TAB" . 'copilot-accept-completion)
                ("C-TAB" . 'copilot-accept-completion-by-word)
                ("C-<tab>" . 'copilot-accept-completion-by-word))))

(after! lsp-mode
  (map! :map lsp-mode-map
        "C-SPC" #'lsp-extend-selection))

;; add org agenda files
(after! org
  (setq org-agenda-files '("~/base/docs/todo.org")))

(setq lsp-julia-package-dir nil)
(setq lsp-julia-default-environment "~/.julia/environments/v1.10")

;; transparency
(set-frame-parameter nil 'alpha-background 1.0)
(add-to-list 'default-frame-alist '(alpha-background . 1.0))

(defun my-cargo-run-release ()
  "Run 'cargo run --release' one folder back relative to the current buffer's directory.
  maybe even make the buffer floating"
  (interactive)
  (let ((default-directory (locate-dominating-file (buffer-file-name) "Cargo.toml")))
    (compile "cargo run --release")))

(defun my-cargo-test ()
  "Run 'cargo run --release' one folder back relative to the current buffer's directory.
  maybe even make the buffer floating"
  (interactive)
  (let ((default-directory (locate-dominating-file (buffer-file-name) "Cargo.toml")))
    (compile "cargo test main -- --nocapture")))

;; Bind the function to the key sequence C-c C-c C-R
;;
(map! :map rust-mode-map
      "C-c C-b" #'my-cargo-test)

;; disable evil o/O to continue comments
(setq +evil-want-o/O-to-continue-comments nil)
(setq +default-want-RET-continue-comments t)

;; activate lsp inlay hints and add a 0.5 second delay
(after! lsp-mode
  (setq lsp-inlay-hint-enable t)
  (setq lsp-idle-delay 1.0))

;; fix to find all files inside a project
(setq projectile-enable-caching nil)
