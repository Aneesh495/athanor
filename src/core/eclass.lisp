;;;; eclass.lisp - Equivalence Class Container and Parent Indexing

(in-package #:athanor)

(defstruct (eclass (:constructor %make-eclass) (:conc-name eclass-))
  "An e-class groups e-nodes known to be mathematically equivalent, maintaining parent pointers."
  (id 0 :type e-id)
  (nodes nil :type list)
  (parents nil :type list)
  (data nil :type t))

(defun make-eclass (id &optional (initial-node nil) (initial-data nil))
  "Allocate a new e-class with identifier ID and optional initial node and analysis data."
  (let ((ec (%make-eclass :id id :data initial-data)))
    (when initial-node
      (push initial-node (eclass-nodes ec)))
    ec))

(defun eclass-size (ec)
  "Return the number of equivalent e-nodes contained within this e-class."
  (declare (type eclass ec))
  (length (eclass-nodes ec)))

(defun add-enode-to-eclass (ec node)
  "Add NODE to EC if not already present. Returns T if added, NIL if already member."
  (declare (type eclass ec)
           (type enode node))
  (unless (member node (eclass-nodes ec) :test #'enode-equal-p)
    (push node (eclass-nodes ec))
    t))

(defun remove-enode-from-eclass (ec node)
  "Remove NODE from EC. Returns T if node was found and removed, NIL otherwise."
  (declare (type eclass ec)
           (type enode node))
  (let ((before (length (eclass-nodes ec))))
    (setf (eclass-nodes ec) (delete node (eclass-nodes ec) :test #'enode-equal-p))
    (/= before (length (eclass-nodes ec)))))

(defun add-parent-to-eclass (ec parent-node parent-class-id)
  "Record that PARENT-NODE (belonging to PARENT-CLASS-ID) references this e-class."
  (declare (type eclass ec)
           (type enode parent-node)
           (type e-id parent-class-id))
  (let ((entry (cons parent-node parent-class-id)))
    (unless (member entry (eclass-parents ec)
                    :test (lambda (a b)
                            (and (= (cdr a) (cdr b))
                                 (enode-equal-p (car a) (car b)))))
      (push entry (eclass-parents ec)))))
