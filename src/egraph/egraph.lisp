;;;; egraph.lisp - Primary E-Graph Container and Insertion Primitives

(in-package #:athanor)

(defstruct (egraph (:constructor %make-egraph) (:conc-name egraph-))
  "The E-Graph represents an exponential space of equivalent expressions as a compact congruence closure."
  (union-find (make-union-find) :type union-find)
  (classes (make-hash-table :test 'eql) :type hash-table)
  (hash-cons (make-hash-cons) :type hash-cons)
  (worklist nil :type list)
  (clean-p t :type boolean)
  (analysis nil :type t))

(defun make-egraph (&key (analysis nil))
  "Allocate a fresh, empty e-graph with optional analysis lattice hooks."
  (%make-egraph :union-find (make-union-find)
                :classes (make-hash-table :test 'eql)
                :hash-cons (make-hash-cons)
                :worklist nil
                :clean-p t
                :analysis analysis))

(defun egraph-find (eg id)
  "Find the canonical root e-class ID for ID within the e-graph."
  (declare (type egraph eg)
           (type e-id id))
  (uf-find (egraph-union-find eg) id))

(defun get-eclass (eg id)
  "Retrieve the eclass structure for canonical root ID."
  (declare (type egraph eg)
           (type e-id id))
  (let ((root (egraph-find eg id)))
    (gethash root (egraph-classes eg))))

(defun egraph-add (eg node)
  "Insert an e-node into the e-graph, ensuring canonicalization and structural sharing.
   Returns the canonical e-class ID containing this node."
  (declare (type egraph eg)
           (type enode node)
           (optimize (speed 3) (safety 1)))
  (let* ((uf (egraph-union-find eg))
         (hc (egraph-hash-cons eg))
         ;; Canonicalize child pointers to current union-find roots
         (canon (canonicalize-enode node uf))
         (existing (hc-lookup hc canon)))
    (if existing
        (uf-find uf existing)
        (let* ((new-id (uf-make-set uf))
               (new-eclass (make-eclass new-id canon)))
          ;; Check node limit budget
          (when (> (uf-count uf) *node-limit*)
            (error 'node-limit-exceeded-error
                   :current-nodes (uf-count uf)
                   :limit *node-limit*))
          ;; Register node in hash-cons
          (hc-insert hc canon new-id)
          ;; Register class in classes table
          (setf (gethash new-id (egraph-classes eg)) new-eclass)
          ;; Register this node as a parent in all its child classes
          (loop for i from 0 below (length (enode-children canon))
                for child-id of-type e-id = (aref (enode-children canon) i)
                for child-class = (get-eclass eg child-id)
                do (when child-class
                     (add-parent-to-eclass child-class canon new-id)))
          ;; Trigger initial analysis if active
          (when (egraph-analysis eg)
            (setf (eclass-data new-eclass)
                  (analysis-make (egraph-analysis eg) canon eg)))
          new-id))))

(defun egraph-add-expr (eg expr)
  "Recursively insert an arbitrary S-expression tree EXPR into the e-graph.
   Returns the e-class ID representing EXPR."
  (declare (type egraph eg))
  (cond
    ;; Leaf literal or atomic symbol
    ((atom expr)
     (egraph-add eg (make-enode expr #())))
    ;; Compound expression (op . args)
    ((consp expr)
     (let* ((op (car expr))
            (args (cdr expr))
            (child-ids (make-array (length args) :element-type 'e-id)))
       (loop for i from 0
             for arg in args
             do (setf (aref child-ids i) (egraph-add-expr eg arg)))
       (egraph-add eg (make-enode op child-ids))))
    (t
     (error 'athanor-error :message (format nil "Invalid expression to add to e-graph: ~S" expr)))))

(defun egraph-merge (eg id1 id2)
  "Merge equivalence classes ID1 and ID2 in the e-graph.
   Returns the canonical root of the joined e-class.
   If already equivalent, returns root immediately."
  (declare (type egraph eg)
           (type e-id id1 id2))
  (let* ((uf (egraph-union-find eg))
         (root1 (uf-find uf id1))
         (root2 (uf-find uf id2)))
    (if (= root1 root2)
        root1
        (let* ((new-root (uf-union uf root1 root2))
               (stale-root (if (= new-root root1) root2 root1))
               (classes (egraph-classes eg))
               (class-new (gethash new-root classes))
               (class-stale (gethash stale-root classes)))
          (setf (egraph-clean-p eg) nil)
          ;; Push merged class to worklist for upward rebuilding
          (push new-root (egraph-worklist eg))
          ;; Merge nodes and parent sets into the canonical class
          (when (and class-new class-stale)
            (dolist (node (eclass-nodes class-stale))
              (add-enode-to-eclass class-new node))
            (dolist (parent (eclass-parents class-stale))
              (add-parent-to-eclass class-new (car parent) (cdr parent)))
            ;; Merge analysis values if an analysis domain is defined
            (when (egraph-analysis eg)
              (setf (eclass-data class-new)
                    (analysis-join (egraph-analysis eg)
                                   (eclass-data class-new)
                                   (eclass-data class-stale))))
            ;; Remove the stale root entry from the classes table
            (remhash stale-root classes))
          new-root))))

(defun in-same-class-p (eg id1 id2)
  "Predicate checking whether ID1 and ID2 are currently in the same equivalence class."
  (declare (type egraph eg)
           (type e-id id1 id2))
  (= (egraph-find eg id1) (egraph-find eg id2)))

(defun egraph-class-count (eg)
  "Return total number of active equivalence classes in the e-graph."
  (hash-table-count (egraph-classes eg)))

(defun egraph-node-count (eg)
  "Return total number of e-nodes across all equivalence classes."
  (let ((total 0))
    (maphash (lambda (k ec)
               (declare (ignore k))
               (incf total (eclass-size ec)))
             (egraph-classes eg))
    total))

(defun lookup-expr (eg expr)
  "Find the e-class ID corresponding to EXPR if it exists in the e-graph, or NIL."
  (cond
    ((atom expr)
     (let ((node (canonicalize-enode (make-enode expr #()) (egraph-union-find eg))))
       (let ((id (hc-lookup (egraph-hash-cons eg) node)))
         (when id (egraph-find eg id)))))
    ((consp expr)
     (let* ((op (car expr))
            (args (cdr expr))
            (child-ids (make-array (length args) :element-type 'e-id))
            (all-found t))
       (loop for i from 0
             for arg in args
             for cid = (lookup-expr eg arg)
             do (if cid
                    (setf (aref child-ids i) cid)
                    (progn (setf all-found nil) (return))))
       (when all-found
         (let ((node (canonicalize-enode (make-enode op child-ids) (egraph-union-find eg))))
           (let ((id (hc-lookup (egraph-hash-cons eg) node)))
             (when id (egraph-find eg id)))))))
    (t nil)))

(defun print-egraph-summary (eg &optional (stream t))
  "Print diagnostic summary of e-graph size, classes, and cleanliness status."
  (format stream "E-Graph Summary: ~D classes, ~D nodes, clean=~A, worklist-len=~D~%"
          (egraph-class-count eg)
          (egraph-node-count eg)
          (egraph-clean-p eg)
          (length (egraph-worklist eg))))
