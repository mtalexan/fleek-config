;;; fleek-template.el --- Native Jinja and host-mode switching -*- lexical-binding: t; -*-

(require 'cl-lib)
(autoload 'web-mode "web-mode" nil t)

(defvar-local fleek-template-host-mode nil)
(put 'fleek-template-host-mode 'permanent-local t)
(defvar-local fleek-template-active nil)
(put 'fleek-template-active 'permanent-local t)

(defun fleek-template-detect-host ()
  "Use native file detection on the name before the Jinja suffix."
  (when buffer-file-name
    (let ((file (replace-regexp-in-string
                 "\\.\\(?:j2\\|jinja2?\\)\\'" "" buffer-file-name)))
      (if (string-match-p "\\.sls\\'" file)
          'yaml-mode
        (unless (equal file buffer-file-name)
          (with-temp-buffer
            (let ((buffer-file-name file)
                  (enable-local-variables nil))
              (delay-mode-hooks (set-auto-mode)))
            (unless (memq major-mode '(fundamental-mode fleek-jinja-mode web-mode))
              major-mode)))))))

(define-derived-mode fleek-jinja-mode web-mode "Jinja"
  "Edit Jinja templates and remember their native host major mode."
  (setq fleek-template-active t)
  (unless fleek-template-host-mode
    (setq fleek-template-host-mode (fleek-template-detect-host)))
  (web-mode-set-engine "django"))

(defun fleek-template-choose-host ()
  "Choose any configured major mode as the current template's host."
  (interactive)
  (unless fleek-template-active
    (user-error "This buffer is not a Jinja template"))
  (let ((mode (intern (completing-read
                       "Template host mode: " obarray
                       (lambda (symbol)
                         (and (commandp symbol)
                              (or (get symbol 'derived-mode-parent)
                                  (rassq symbol auto-mode-alist)
                                  (rassq symbol interpreter-mode-alist)
                                  (rassq symbol magic-mode-alist))
                              (not (eq symbol 'fleek-jinja-mode))))
                       t))))
    (setq fleek-template-host-mode mode)
    (unless (eq major-mode 'fleek-jinja-mode)
      (fleek-template-switch mode))))

(defun fleek-template-switch (mode)
  "Switch the current buffer to MODE without modifying its text or filename."
  (let ((position (point)))
    (funcall mode)
    (goto-char (min position (point-max)))))

(defun fleek-template-toggle ()
  "Toggle between Jinja and the remembered host major mode."
  (interactive)
  (unless fleek-template-active
    (user-error "This buffer is not a Jinja template"))
  (if (eq major-mode 'fleek-jinja-mode)
      (progn
        (unless fleek-template-host-mode (fleek-template-choose-host))
        (fleek-template-switch fleek-template-host-mode))
    (fleek-template-switch 'fleek-jinja-mode)))

(provide 'fleek-template)
;;; fleek-template.el ends here
