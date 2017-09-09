;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                  ;;;
;;; Free Software published under an MIT-like license. See LICENSE   ;;;
;;;                                                                  ;;;
;;; Copyright (c) 2017      TurtleWare    All rights reserved.       ;;;
;;;                                                                  ;;;
;;; Original author: Daniel Kochmański                               ;;;
;;;                                                                  ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(in-package :qmynd-impl)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; 14.9.9 command-register-slave

;; We don't actually receive this packet as a client, but it looks like this.

#+ (or)
(define-packet command-register-slave
    ;;; In return we expect `OK' or `ERR' packet.
    ((tag :mysql-type (integer 1) :value +com-register-slave+ :transient t :bind nil)
     (server-id         :mysql-type (integer 4) :value +slave-id+)
     (slaves-host-len   :mysql-type (integer 1))
     (slaves-hostname   :mysql-type (string :lenenc))
     (slaves-user-len   :mysql-type (integer 1))
     (slaves-user       :mysql-type (string :lenenc))
     (slaves-pass-len   :mysql-type (integer 1))
     (slaves-pass       :mysql-type (string :lenenc))
     (slaves-mysql-port :mysql-type (integer 2))
     (replication-rank  :mysql-type (octets 4))
     (master-id         :mysql-type (integer 4))))

(defun send-command-register-slave (slave-id)
  (mysql-command-init +mysql-command-register-slave+)
  (mysql-write-packet
   (flexi-streams:with-output-to-sequence (s)
     (write-fixed-length-integer +mysql-command-register-slave+ 1 s)
     (write-fixed-length-integer slave-id                       4 s)
     #| next 5 fields are usually ignored |#
     (write-fixed-length-integer 0 1 s) ; slave hostname
     (write-fixed-length-integer 0 1 s) ; username
     (write-fixed-length-integer 0 1 s) ; password
     (write-fixed-length-integer 0 2 s) ; slaves-port
     ;; (write-length-encoded-octets (babel:string-to-octets "localhost") s)
     ;; (write-length-encoded-octets (babel:string-to-octets username)    s)
     ;; (write-length-encoded-octets (babel:string-to-octets password)    s)
     ;; (write-fixed-length-integer  +slave-port+ 2 s)
     #| replication rank is not used |#
     (write-fixed-length-integer 0 4 s)
     ;; master ID, 0 is OK
     (write-fixed-length-integer 0 4 s)))
  (parse-response (mysql-read-packet)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; 14.9.5 command-binary-log-dump

;; We don't actually receive this packet as a client, but it looks like this.
#+ (or)
(define-packet command-binary-log-dump
    ;;; In return we expect `binary-log-event' stream or `EOF' packet.
    ((tag :mysql-type (integer 1) :value +mysql-command-binary-log-dump+ :transient t :bind nil)
     (binlog-pos      :mysql-type (integer 4))
     (flags           :mysql-type (integer 2)) ; `+mysql-flag-binary-log-dump-non-block+'
     (server-id       :mysql-type (integer 4) :value +slave-id+)
     (binlog-filename :mysql-type (string :eof))))

(defun send-command-binary-log-dump (slave-id binary-log-position
                                     &optional non-blocking binary-log-filename)
  (mysql-command-init +mysql-command-binary-log-dump+)
  (mysql-write-packet
   (flexi-streams:with-output-to-sequence (s)
     (write-fixed-length-integer +mysql-command-binary-log-dump+ 1 s)
     (write-fixed-length-integer binary-log-position             4 s)
     (write-fixed-length-integer
      (if (null non-blocking)
          #x00
          +mysql-flag-binary-log-dump-non-block+)
      2 s)
     (write-fixed-length-integer slave-id 4 s) ; slave server id (unique)
     ;; binlog filename
     (when binary-log-filename
       (write-sequence (babel:string-to-octets binary-log-filename) s)))))

