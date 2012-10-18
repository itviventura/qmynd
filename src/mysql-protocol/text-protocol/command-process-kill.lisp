;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                  ;;;
;;; Free Software published under an MIT-like license. See LICENSE   ;;;
;;;                                                                  ;;;
;;; Copyright (c) 2012 Google, Inc.  All rights reserved.            ;;;
;;;                                                                  ;;;
;;; Original author: Alejandro Sedeño                                ;;;
;;;                                                                  ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(in-package :mysqlnd)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; 15.6.13 command-process-kill

;; We don't actually receive this packet as a client, but it looks like this.

;; (define-packet command-process-kill
;;   ((tag :mysql-type (integer 1)
;;         :value +mysql-command-process-kill+
;;         :transient t :bind nil)
;;    (connection-id :mysql-type (integer 4))))

;; Returns OK or ERR packet

(defun send-command-process-kill (connection-id)
  (assert (typep connection-id '(unsigned-byte 32)))
  (with-mysql-connection (c)
    (mysql-command-init c +mysql-command-process-kill+)
    (mysql-write-packet (vector +mysql-command-process-kill+ connection-id))
    (parse-response (mysql-read-packet))))