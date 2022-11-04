;; -*- lexical-binding: t; -*-

;; Requires: esxml

(require 'esxml)

(defun dotweaver-default-page-header-func (file-path)
  (sxml-to-xml `(div (h2 "dotweaver")
                     (h3 "Browsing: " ,file-path))))

(defvar dotweaver-page-header-func #'dotweaver-default-page-header-func
  "A user-customizable function that generates the header for site
pages.")

(defun dotweaver--page-header (file style)
  (format "<?xml version=\"1.0\" encoding=\"utf-8\"?>
<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.1//EN\"
\"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd\">
<html xmlns=\"http://www.w3.org/1999/xhtml\">
  <head>
    <meta charset=\"utf-8\"/>
    <title>%s</title>
%s
  </head>
  <body>\n
    %s
"
          (mapconcat #'hfy-html-quote (mapcar #'char-to-string file) "")
          style
          (funcall dotweaver-page-header-func file)))

(defun dotweaver-generate-current-buffer (&optional output-path)
  (interactive)
  ;; TODO: More stuff
  (let ((hfy-page-header #'dotweaver--page-header))
    (with-current-buffer (htmlfontify-buffer)
      (let ((doc (libxml-parse-html-region (point-min)
                                           (point-max))))
        ;; Clear the HTML buffer
        ;; (delete-region (point-min)
        ;;                (point-max))

        ;; Manipulate the contents and write it back to the buffer
        ;; (dom-remove-node doc (car (dom-search doc (lambda (node)
        ;;                                             (and (string= (dom-tag node) "meta")
        ;;                                                  (string= (dom-attr node 'name) "generator"))))))
        ;; (dom-print doc)
        (write-file (buffer-file-name))))))

(defun dotweaver-generate-file (input-file input-path output-path)
  (with-current-buffer (find-file-noselect (expand-file-name input-file
                                                             input-path))
    (let ((hfy-page-header #'dotweaver--page-header))
      (with-current-buffer (htmlfontify-buffer)
        (read-only-mode 1)
        (write-file (concat (expand-file-name input-file
                                              output-path)
                            ".html"))
        (read-only-mode 0)))))

(defun dotweaver--get-tracked-files (input-path)
  (let* ((default-directory input-path)
         (tracked-files (split-string (shell-command-to-string "git ls-tree --full-tree --name-only -r HEAD"))))
    tracked-files))

(dotweaver--get-tracked-files "~/.dotfiles")

(defun dotweaver-generate-site (input-path output-path)
  (let ((input-files (dotweaver--get-tracked-files input-path)))
    (dolist (file input-files)
      (dotweaver-generate-file file input-path output-path))))

(dotweaver-generate-site "~/.dotfiles" (expand-file-name "output"))

(provide 'dotweaver)
