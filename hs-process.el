;;; hs-process.el — Interaction with the inferior process.

;; Copyright (C) 2011 Chris Done

;; This program is free software: you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see
;; <http://www.gnu.org/licenses/>.

;;; Commentary:

;;; Code:

(require 'hs-lang-en)
(require 'hs-types)

(require 'cl)

(defun hs-process ())

(defun hs-process-start (project)
  "Start the inferior haskell process."
  (let ((process (hs-process-make :cmd 'startup
                                  :name (hs-project-name project)
                                  :response ""
                                  :response-cursor 0
                                  :load-dirs '()
                                  :current-dir (hs-project-cabal-dir project)
                                  :response-callback nil)))
    (setf (hs-process-process process)
          (start-process
           (hs-process-name process)
           nil
           hs-config-cabal-dev-bin))
    (set-process-filter (hs-process-process process)
                        'hs-process-filter)
    (setf (hs-project-process project) process)))

(defun hs-process-filter (proc response)
  "The filter for the process pipe."
  (let ((project (hs-process-project-by-proc proc)))
    (when project
      (when (not (eq (hs-process-cmd (hs-project-process project))
                     'none))
        (hs-process-collect project response)))))

(defun hs-process-project-by-proc (proc)
  "Find project by process."
  (find-if (lambda (project)
             (string= (hs-project-name project)
                      (process-name proc)))
           *hs-projects*))

(defun hs-process-collect (project response)
  "Collect input for the response until receives a prompt."
  (let ((process (hs-project-process project)))
   (setf (hs-process-response process)
         (concat (hs-process-response process) response))
   (while (hs-process-live-updates process))))

(defun hs-process-live-updates (process)
  "Trigger any updates that happen during receiving a response."
  (case (hs-process-cmd process)
    ('arbitrary (hs-process-trigger-arbitrary-updates process))))

(defun hs-process-trigger-arbitrary-updates (process)
  "Just log out any arbitrary output."
  (let ((new-data (substring (hs-process-response process)
                             (hs-process-response-cursor process))))
    ;(hs-buffer-echo-read-only-incomplete session new-data)
    (message new-data)
    (setf (hs-process-response-cursor process)
          (+ (hs-process-response-cursor session)
             (length new-data)))
    nil))

(defun hs-process-trigger-background-arbitrary-updates (process)
  "Just log out any arbitrary output."
  (let ((new-data (substring (hs-process-response session)
                             (hs-process-response-cursor session))))
    (mapc 'message (split-string new-data "\n"))
    (setf (hs-process-response-cursor session)
          (+ (hs-process-response-cursor session) (length new-data)))
    nil))

(provide 'hs-process)