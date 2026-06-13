;;; publish.el, builds kris.sh from org sources because muh emacs -*- lexical-binding: t; -*-
;;; Commentary: this was a stupid bad idea that somehow works really fuckin well
;; usage: emacs --batch -Q -l publish.el
;; this should shit everything out into public/

(require 'ox-publish)
(require 'ox-html)

;; global export behaviour
;;; Code:
(setq org-html-toplevel-hlevel 1 ; org "*"  -> <h1>  (== markdown #)
      org-html-doctype "html5" ; <!DOCTYPE html>
      org-html-html5-fancy nil ; special blocks -> plain <div>
      org-html-validation-link nil ; no validation links org would normally add
      org-html-head-include-default-style nil ; don't inject orgs builtin <style>
      org-html-head-include-scripts nil ; don't inject orgs built in JS stuff
      org-export-with-section-numbers nil ; no "1.2.3" prefixes on headings
      org-export-with-toc nil ; no auto table of contents
      org-export-with-author nil ; no author line
      org-export-time-stamp-file nil ; no created <date> comment in output
      org-export-with-smart-quotes nil ; leave my " and ' alone
      make-backup-files nil) ; no xyz.org~ backups

;; directory containing this file, load-file-name is set when run via '-l'
;; buffer-file-name is a fallback incase i want to eval from a live buffer
;; everything below is resolved relative to this
(defconst kris-root (file-name-directory (or load-file-name buffer-file-name)))

(defconst kris-head
  (concat
   "<meta charset=\"utf-8\">\n"
   "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n"
   "<link rel=\"icon\" href=\"/favicon.ico\">\n"
   "<link rel=\"alternate\" type=\"application/rss+xml\" title=\"kris.sh\" href=\"/posts/index.xml\">\n"
   "<link rel=\"stylesheet\" href=\"/css/main.css\">"))

;; shared header (nav)
(defun kris-navlink (href label active)
  (format "<a class=\"%snavContent\" href=\"%s\">%s</a>"
          (if active "active" "") href label))

(defun kris-preamble (info)
  "Return the <header> block, highlighting the active section."
  (let* ((file (or (plist-get info :input-file) ""))
         (sect (cond ((string-match-p "/posts/" file) 'blog)
                     ((string-match-p "/services/" file) 'services)
                     (t 'home))))
    (concat
     "<header><div class=\"top\">\n"
     "<a class=\"homeheader\" href=\"/\">kris.sh</a>\n"
     "<div class=\"nav\">\n"
     (kris-navlink "/" "~/" (eq sect 'home)) "\n"
     (kris-navlink "/posts/" "~/blog" (eq sect 'blog)) "\n"
     (kris-navlink "/services/" "~/services" (eq sect 'services)) "\n"
     "<a class=\"navContent\" href=\"/posts/index.xml\" title=\"blog RSS feed\">~/rss</a>\n"
     "</div></div></header>")))

;; shared footer
(defconst kris-postamble
  (concat
   "<footer>\n"
   "<p>If you run <strong>curl ip.kris.sh</strong> in a terminal/cmd, "
   "it will return your public IP address.</p>\n"
   "<a class=\"a2\" href=\"https://voidlinux.org/\"><img src=\"/voidlinux.gif\" alt=\"Void Linux\"></a>\n"
   "<img src=\"/javascript.gif\" alt=\"\">\n"
   "<img src=\"/linux_now.gif\" alt=\"\">\n"
   "<img src=\"/gnu.png\" alt=\"GNU\">\n"
   "</footer>"))

;; fix site links, without this org [[/services][..]] will "render" to file:///
;; which obviously doesn't work with html documents
(defun kris-fix-internal-links (output backend _info)
  (if (org-export-derived-backend-p backend 'html)
      (replace-regexp-in-string "\\(href=\"\\|src=\"\\)file:///" "\\1/" output)
    output))
(add-to-list 'org-export-filter-final-output-functions #'kris-fix-internal-links)

;; project
(setq org-publish-project-alist
      `(("kris-pages"
         ;; recursively read .org files out of src/
         :base-directory ,(expand-file-name "src" kris-root)
         :base-extension "org"
         :recursive t
         ;; write rendered html into public/ while mirroring the tree
         :publishing-directory ,(expand-file-name "public" kris-root)
         :publishing-function org-html-publish-to-html
         ;; per page shit like <head>, header, footer
         :html-head ,kris-head
         ;; make sure the project plist has precedence
         :html-head-include-default-style nil
         :html-head-include-scripts nil
         :html-preamble kris-preamble ;; function, called with INFO per page
         :html-postamble ,kris-postamble ;; same footer on every page
         :with-toc nil
         :section-numbers nil)
        ("kris-static"
         ;; same src tree but match asset extensions and copy them verbatim
         :base-directory ,(expand-file-name "src" kris-root)
         :base-extension "css\\|woff2\\|woff\\|ttf\\|gif\\|png\\|jpe?g\\|ico\\|svg\\|txt" ;; the random shit to match and copy to the build
         :recursive t
         :publishing-directory ,(expand-file-name "public" kris-root)
         :publishing-function org-publish-attachment)
        ("kris" :components ("kris-pages" "kris-static")))) ;; publishing "kris" runs both components in order

;; execution, "t" here forces a rebuild of *everything* so
;; files whose source hasnt changed aren't skipped
(org-publish "kris" t) ; t => force rebuild

;; RSS generation via webfeeder: https://elpa.gnu.org/packages/webfeeder.html
(require 'package)
(package-initialize)
(require 'webfeeder)

(defun kris-feed-title (html-file)
  "Entry title from <title>, minus the \" | kris.sh\" suffix."
  (let ((title (webfeeder-title-libxml html-file)))
    (when title (replace-regexp-in-string " *| *kris\\.sh\\'" "" title))))
 
(defun kris-feed-date (html-file)
  "Entry date, read from the post's <time datetime=\"...\"> stamp."
  (with-temp-buffer
    (insert-file-contents html-file)
    (goto-char (point-min))
    (if (re-search-forward "datetime=\"\\([^\"]+\\)\"" nil t)
        (date-to-time (match-string 1))
      0)))
 
(let* ((public (expand-file-name "public" kris-root))
       ;; every built post page, but not the /posts/ listing index
       (posts (let (acc)
                (dolist (f (directory-files-recursively
                            (expand-file-name "posts" public) "index\\.html\\'"))
                  (let ((rel (file-relative-name f public)))
                    (unless (string= rel "posts/index.html") (push rel acc))))
                (nreverse acc)))
       (webfeeder-title-function #'kris-feed-title)
       (webfeeder-date-function  #'kris-feed-date))
  (webfeeder-build "posts/index.xml" public "https://kris.sh/" posts
                   :title "kris.sh"
                   :description "Posts from kris.sh"
                   :builder 'webfeeder-make-rss)
  (message "RSS: wrote %d items" (length posts)))

(message "Build complete.")
;;; publish.el ends here
