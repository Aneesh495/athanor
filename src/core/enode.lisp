;;;; enode.lisp - Equivalence Node Representation, Canonicalization, and Hashing

(in-package #:athanor)

(defstruct (enode (:constructor %make-enode) (:conc-name enode-))
  "An e-node represents an operator or constant whose arguments are e-class identifiers."
  (op nil :type t)
  (children #() :type (simple-array e-id (*)))
  (hash 0 :type fixnum)
  (constant-p nil :type boolean))

(defun compute-enode-hash (op children)
  "Calculate a deterministic 30-bit integer hash code for an operator and its child e-class IDs."
  (declare (type t op)
           (type (simple-array e-id (*)) children)
           (optimize (speed 3) (safety 0)))
  (let ((h (sxhash op)))
    (declare (type fixnum h))
    (loop for i from 0 below (length children)
          for child-id of-type e-id = (aref children i)
          do (setf h (mix-hash h (sxhash child-id))))
    h))

(defun make-enode (op &optional (children #()))
  "Construct an e-node from an operator symbol or literal and a sequence of child e-class IDs."
  (let* ((child-array (if (typep children '(simple-array e-id (*)))
                          children
                          (let ((arr (make-array (length children) :element-type 'e-id)))
                            (loop for i from 0
                                  for c in (if (listp children) children (coerce children 'list))
                                  do (setf (aref arr i) (the e-id c)))
                            arr)))
         (is-const (and (zerop (length child-array))
                        (or (numberp op) (stringp op) (keywordp op))))
         (h (compute-enode-hash op child-array)))
    (%make-enode :op op
                 :children child-array
                 :hash h
                 :constant-p is-const)))

(defun enode-equal-p (n1 n2)
  "Test structural equality between two e-nodes."
  (declare (type enode n1 n2)
           (optimize (speed 3) (safety 0)))
  (when (= (enode-hash n1) (enode-hash n2))
    (and (equal (enode-op n1) (enode-op n2))
         (let ((c1 (enode-children n1))
               (c2 (enode-children n2)))
           (and (= (length c1) (length c2))
                (loop for i from 0 below (length c1)
                      always (= (aref c1 i) (aref c2 i))))))))

(defun canonicalize-enode (node uf)
  "Return a canonical copy of NODE where each child ID is replaced by its union-find root."
  (declare (type enode node)
           (type union-find uf)
           (optimize (speed 3) (safety 1)))
  (let* ((children (enode-children node))
         (len (length children))
         (changed nil)
         (new-children (make-array len :element-type 'e-id)))
    (loop for i from 0 below len
          for child-id of-type e-id = (aref children i)
          for root of-type e-id = (uf-find uf child-id)
          do (setf (aref new-children i) root)
             (when (/= child-id root)
               (setf changed t)))
    (if changed
        (make-enode (enode-op node) new-children)
        node)))

(defun enode-to-sexpr (node)
  "Convert an e-node to a readable S-expression form (with child IDs shown directly)."
  (let ((op (enode-op node))
        (children (coerce (enode-children node) 'list)))
    (if children
        (cons op children)
        op)))
