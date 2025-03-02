;;;; hash-cons.lisp - Memoization and Structural Sharing for Canonical E-Nodes

(in-package #:athanor)

(defstruct (hash-cons (:constructor %make-hash-cons))
  "Hash-consing table mapping canonical e-nodes to their containing e-class IDs."
  (table (make-hash-table :test #'enode-equal-p :hash-function #'enode-hash)
   :type hash-table))

(defun make-hash-cons ()
  "Construct an empty hash-consing table."
  (%make-hash-cons :table (make-hash-table :test #'enode-equal-p :hash-function #'enode-hash)))

(defun hc-lookup (hc node)
  "Find the e-class ID associated with canonical NODE in the table, or NIL if absent."
  (declare (type hash-cons hc)
           (type enode node))
  (gethash node (hash-cons-table hc)))

(defun hc-insert (hc node class-id)
  "Store the association between canonical NODE and CLASS-ID."
  (declare (type hash-cons hc)
           (type enode node)
           (type e-id class-id))
  (setf (gethash node (hash-cons-table hc)) class-id))

(defun hc-remove (hc node)
  "Remove the association for NODE from the table."
  (declare (type hash-cons hc)
           (type enode node))
  (remhash node (hash-cons-table hc)))

(defun hc-count (hc)
  "Return total number of entries in the hash-consing table."
  (declare (type hash-cons hc))
  (hash-table-count (hash-cons-table hc)))

(defun hc-clear (hc)
  "Empty all entries from the hash-consing table."
  (declare (type hash-cons hc))
  (clrhash (hash-cons-table hc)))

(defun hc-entries (hc)
  "Return an alist of (enode . class-id) pairs currently tracked in the table."
  (declare (type hash-cons hc))
  (let ((acc nil))
    (maphash (lambda (k v) (push (cons k v) acc)) (hash-cons-table hc))
    acc))
