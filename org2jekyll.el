;;; org2jekyll.el --- Minor mode to publish org-mode post to jekyll without specific yaml

;; Copyright (C) 2014 Antoine R. Dumont <eniotna.t AT gmail.com>

;; Author: Antoine R. Dumont <eniotna.t AT gmail.com>
;; Maintainer: Antoine R. Dumont <eniotna.t AT gmail.com>
;; Version: 0.0.4
;; Package-Requires: ((dash "2.8.0") (s "1.9.0") (deferred "0.3.2"))
;; Keywords: org-mode jekyll blog publish
;; URL: https://github.com/ardumont/org2jekyll

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING. If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; Functions to ease publishing jekyll posts from org-mode file

;; Providing you have a working `'jekyll`' and `'org-publish`'
;; This will permit you to simply export an org-mode file to the right format to
;; the right folder for jekyll to understand
;;
;; M-x org2jekyll/create-draft! create a draft with the necessary metadata
;;
;; M-x org2jekyll/publish-post! publish the post to the jekyll folder
;;
;; More information on https://github.com/ardumont/org2jekyll

;;; Code:

(require 'org)
(require 'dash)
(require 's)

(defgroup org2jekyll nil " Org2jekyll customisation group."
  :tag "org2jekyll"
  :version "0.0.3"
  :group 'org)

(defcustom org2jekyll/blog-entry nil
  "Blog entry name."
  :type 'string
  :require 'org2jekyll
  :group 'org2jekyll)

(defcustom org2jekyll/blog-author nil
  "Blog entry author."
  :type 'string
  :require 'org2jekyll
  :group 'org2jekyll)

(defcustom org2jekyll/source-directory nil
  "Path to the source directory."
  :type 'string
  :require 'org2jekyll
  :group 'org2jekyll)

(defcustom org2jekyll/jekyll-directory nil
  "Path to Jekyll blog."
  :type 'string
  :require 'org2jekyll
  :group 'org2jekyll)

(defcustom org2jekyll/jekyll-drafts-dir nil
  "Relative path to drafts directory."
  :type 'string
  :require 'org2jekyll
  :group 'org2jekyll)

(defcustom org2jekyll/jekyll-posts-dir nil
  "Relative path to posts directory."
  :type 'string
  :require 'org2jekyll
  :group 'org2jekyll)

(defvar org2jekyll/jekyll-post-ext ".org"
  "File extension of Jekyll posts.")

(defvar org2jekyll/jekyll-org-post-template "#+STARTUP: showall\n#+STARTUP: hidestars\n#+OPTIONS: H:2 num:nil tags:nil toc:1 timestamps:t\n#+BLOG: %s\n#+LAYOUT: post\n#+AUTHOR: %s\n#+DATE: %s\n#+TITLE: %s\n#+DESCRIPTION: %s\n#+CATEGORIES: %s\n\n* "
  "Default template for org2jekyll draft posts.
The `'%s`' will be replaced respectively by the blog entry name, the author, the generated date, the title, the description and the categories.")

(defun org2jekyll/input-directory (&optional folder-name)
  "Compute the input folder from the FOLDER-NAME."
  (format "%s/%s" org2jekyll/source-directory (if folder-name folder-name "")))

(defun org2jekyll/output-directory (folder-name)
  "Compute the output folder from the FOLDER-NAME."
  (format "%s/%s" org2jekyll/jekyll-directory folder-name))

(defun org2jekyll/--make-slug (s)
  "Turn a string S into a slug."
  (replace-regexp-in-string
   " " "-" (downcase
            (replace-regexp-in-string
             "[^A-Za-z0-9 ]" "" s))))

(defun org2jekyll/--yaml-escape (s)
  "Escape a string S for YAML."
  (if (or (string-match ":" s)
          (string-match "\"" s))
      (concat "\"" (replace-regexp-in-string "\"" "\\\\\"" s) "\"")
    s))

;;;###autoload
(defun org2jekyll/create-draft! ()
  "Create a new Jekyll blog post with TITLE."
  (interactive)
  "The `'%s`' will be replaced respectively by the blog entry name, the author, the generated date, the title, the description and the categories."
  (let ((post-blog-entry  org2jekyll/blog-entry)
        (post-author      org2jekyll/blog-author)
        (post-date        (format-time-string "%Y-%m-%d %a %H:%M"))
        (post-title       (read-string "Post Title: "))
        (post-description (read-string "Post Description: "))
        (post-categories  (read-string "Post Categories (comma separated entries): ")))
    (let ((draft-file (concat org2jekyll/jekyll-directory org2jekyll/jekyll-drafts-dir
                              (org2jekyll/--make-slug post-title)
                              org2jekyll/jekyll-post-ext)))
      (if (file-exists-p draft-file)
          (find-file draft-file)
        (progn (find-file draft-file)
               (insert (format org2jekyll/jekyll-org-post-template post-blog-entry post-author post-date (org2jekyll/--yaml-escape post-title) post-description post-categories)))))))

;;;###autoload
(defun org2jekyll/list-posts ()
  "Lists the posts folder."
  (interactive)
  (find-file (org2jekyll/output-directory org2jekyll/jekyll-posts-dir)))

;;;###autoload
(defun org2jekyll/list-drafts ()
  "Lists the drafts folder."
  (interactive)
  (find-file (org2jekyll/output-directory org2jekyll/jekyll-drafts-dir)))

(defun org2jekyll/get-option-at-point! (opt)
  "Gets the header value of the option OPT from a buffer."
  (let* ((regexp (org-make-options-regexp (list (upcase opt) (downcase opt)))))
    (save-excursion
      (goto-char (point-min))
      (if (re-search-forward regexp nil t 1)
          (match-string-no-properties 2)))))

(defun org2jekyll/get-option-from-file! (orgfile option)
  "Return the ORGFILE's OPTION."
  (with-temp-buffer
    (when (file-exists-p orgfile)
      (insert-file-contents orgfile)
      (goto-char (point-min))
      (org2jekyll/get-option-at-point! option))))

(defun org2jekyll/get-options-from-file! (orgfile options)
  "Return the ORGFILE's OPTIONS."
  (with-temp-buffer
    (when (file-exists-p orgfile)
      (insert-file-contents orgfile)
      (mapcar (lambda (option)
                (save-excursion
                  (goto-char (point-min))
                  (cons option (org2jekyll/get-option-at-point! option))))
              options))))

(defun org2jekyll/article-p! (orgfile)
  "Determine if the current ORGFILE is an article or not.
Depends on the metadata header blog."
  (org2jekyll/get-option-from-file! orgfile "BLOG"))

(defun org2jekyll/get-publish-date! (orgfile)
  "Get the publication date from an ORGFILE."
  (org2jekyll/get-option-from-file! orgfile "DATE"))

(defvar org2jekyll/map-keys '(("title" . "title")
                              ("categories" . "categories")
                              ("date" . "date")
                              ("description" . "excerpt")
                              ("author" . "author")
                              ("layout" . "layout")
                              ("blog" . "blog"))
  "Keys to map from org headers to jekyll's headers.")

(defun org2jekyll/--org-to-yaml-metadata (org-metadata)
  "Given an ORG-METADATA map, return a yaml one with transformed data."
  (--map `(,(assoc-default (car it) org2jekyll/map-keys) . ,(cdr it)) org-metadata))

(defun org2jekyll/--convert-timestamp-to-yyyy-dd-mm (timestamp)
  "Convert org TIMESTAMP to ."
  (format-time-string "%Y-%m-%d"
                      (apply 'encode-time (org-parse-time-string timestamp))))

(defun org2jekyll/--to-yaml-header (org-metadata)
  "Given a list of ORG-METADATA, compute the yaml header string."
  (--> org-metadata
    org2jekyll/--org-to-yaml-metadata
    (--map (format "%s: %s" (car it) (cdr it)) it)
    (cons "---" it)
    (cons "#+BEGIN_HTML" it)
    (-snoc it "---")
    (-snoc it "#+END_HTML\n")
    (s-join "\n" it)))

(defun org2jekyll/--categories-csv-to-yaml (categories-csv)
  "Transform a CATEGORIES-CSV entries into a yaml entries."
  (->> categories-csv
    (concat ",")
    (s-replace ", " ",")
    (s-replace "," "\n- ")
    s-trim
    (concat "\n")))

;;;###autoload
(defun org2jekyll/publish-post! (&optional org-file)
  "Publish a post ready for jekyll to render it."
  (interactive)
  (let ((orgfile (if org-file org-file (buffer-file-name (current-buffer)))))
    (if (org2jekyll/article-p! orgfile)
        (let* ((org-metadata             (org2jekyll/get-options-from-file! orgfile '("title" "date" "categories" "description" "author" "blog")))
               (date                     (org2jekyll/--convert-timestamp-to-yyyy-dd-mm (assoc-default "date" org-metadata)))
               (blog-project             (assoc-default "blog" org-metadata))
               (yaml-headers             `(("layout"      . "post")
                                           ("title"       . ,(assoc-default "title" org-metadata))
                                           ("date"        . ,date)
                                           ("categories"  . ,(org2jekyll/--categories-csv-to-yaml (assoc-default "categories" org-metadata)))
                                           ("author"      . ,(assoc-default "author" org-metadata))
                                           ("description" . ,(assoc-default "description" org-metadata))))
               (temp-org-jekyll-filename  (format "%s-%s" date (file-name-nondirectory orgfile)))
               (temp-org-jekyll-directory (file-name-directory orgfile))
               (temp-postfile             (format "%s/%s" temp-org-jekyll-directory temp-org-jekyll-filename)))
          (with-temp-file temp-postfile                 ;; write temporary file updated with jekyll specifics
            (insert-file-contents orgfile)
            (goto-char (point-min))
            (insert (org2jekyll/--to-yaml-header yaml-headers)))
          (org-publish-file temp-postfile (assoc blog-project org-publish-project-alist)) ;; publish the file with the right projects
          (delete-file temp-postfile))                  ;; remove the temporary file
      (message "This file is not an article, skip."))))

;; (global-set-key (kbd "C-c b n") 'org2jekyll/create-draft!)
;; (global-set-key (kbd "C-c b p") 'org2jekyll/publish-post!)
;; (global-set-key (kbd "C-c b l") 'org2jekyll/list-posts)
;; (global-set-key (kbd "C-c b d") 'org2jekyll/list-drafts)

(provide 'org2jekyll)
;;; org2jekyll.el ends here
