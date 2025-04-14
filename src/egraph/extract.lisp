;;;; extract.lisp - AST Extraction Under Customizable Hardware and Structural Cost Models

(in-package #:athanor)

(defparameter +cost-infinity+ 1.0d12
  "Sentinel representation for unreachable or cyclic e-nodes during extraction.")

(defun operator-latency (op)
  "Estimated hardware latency in clock cycles for elementary arithmetic operators."
  (case op
    ((+ - logand logior logxor not ash) 1)
    ((*) 3)
    ((/ mod) 15)
    ((sqrt) 10)
    ((sin cos tan exp log) 30)
    (otherwise 1)))

(defun enode-cost (node child-costs model)
  "Calculate cost of NODE given the costs of its children under the designated MODEL."
  (declare (type enode node)
           (type list child-costs)
           (type keyword model))
  (case model
    (:ast-depth
     (if child-costs
         (1+ (reduce #'max child-costs))
         1))
    (:latency
     (let ((base (operator-latency (enode-op node))))
       (+ base (reduce #'+ child-costs :initial-value 0))))
    (otherwise
     ;; Default: :ast-size
     (1+ (reduce #'+ child-costs :initial-value 0)))))

(defun compute-extraction-costs (eg model)
  "Compute the minimum cost and best representative e-node for every e-class in EG."
  (declare (type egraph eg)
           (type keyword model))
  (let ((best-costs (make-hash-table :test 'eql))
        (best-nodes (make-hash-table :test 'eql))
        (changed t)
        (iter 0)
        (max-iters (* 2 (egraph-class-count eg))))
    ;; Initialize all class costs to infinity
    (maphash (lambda (root-id ec)
               (declare (ignore ec))
               (setf (gethash root-id best-costs) +cost-infinity+)
               (setf (gethash root-id best-nodes) nil))
             (egraph-classes eg))

    ;; Fixed-point dynamic programming relaxation loop
    (loop while (and changed (< iter max-iters))
          do (setf changed nil)
             (incf iter)
             (maphash (lambda (root-id ec)
                        (dolist (node (eclass-nodes ec))
                          (let ((children (enode-children node))
                                (all-finite t)
                                (child-costs nil))
                            (loop for i from 0 below (length children)
                                  for child-id of-type e-id = (egraph-find eg (aref children i))
                                  for c = (gethash child-id best-costs)
                                  do (if (or (null c) (>= c +cost-infinity+))
                                         (progn (setf all-finite nil) (return))
                                         (push c child-costs)))
                            (when all-finite
                              (let ((cand-cost (enode-cost node (nreverse child-costs) model))
                                    (curr-cost (gethash root-id best-costs)))
                                (when (< cand-cost curr-cost)
                                  (setf (gethash root-id best-costs) cand-cost)
                                  (setf (gethash root-id best-nodes) node)
                                  (setf changed t)))))))
                      (egraph-classes eg)))
    (values best-costs best-nodes)))

(defun extract-best-from-class (eg class-id &key (cost-model :ast-size))
  "Reconstruct the optimal S-expression representing CLASS-ID under COST-MODEL."
  (declare (type egraph eg)
           (type e-id class-id)
           (type keyword cost-model))
  (multiple-value-bind (best-costs best-nodes)
      (compute-extraction-costs eg cost-model)
    (let ((root (egraph-find eg class-id)))
      (labels ((build (curr-id visited-set)
                 (let ((cid (egraph-find eg curr-id)))
                   (when (member cid visited-set)
                     (error 'cycle-detected-error :cycle-node cid))
                   (let ((node (gethash cid best-nodes)))
                     (unless node
                       (error 'athanor-error
                              :message (format nil "Unable to extract term from e-class ~D (cost is infinite)" cid)))
                     (let ((children (enode-children node))
                           (op (enode-op node)))
                       (if (zerop (length children))
                           op
                           (let ((next-visited (cons cid visited-set)))
                             (let ((child-exprs
                                     (loop for i from 0 below (length children)
                                           for ch-id of-type e-id = (aref children i)
                                           collect (build ch-id next-visited))))
                               (cons op child-exprs)))))))))
        (values (build root nil) (gethash root best-costs))))))

(defun extract-best (eg class-id &key (cost-model :ast-size))
  "Convenience wrapper for extract-best-from-class."
  (extract-best-from-class eg class-id :cost-model cost-model))

(defun saturate-expr (expr rb &key (cost-model :ast-size)
                                   (max-iterations *max-iterations*)
                                   (analysis nil)
                                   (verbose *verbose*))
  "Convenience pipeline: build e-graph from EXPR, saturate under RB, and extract optimal term.
   Returns (values optimal-expr saturation-report)."
  (let ((eg (make-egraph :analysis analysis)))
    (let ((root-id (egraph-add-expr eg expr)))
      (let ((report (saturate eg rb :max-iterations max-iterations :verbose verbose)))
        (let ((optimal (extract-best eg root-id :cost-model cost-model)))
          (values optimal report))))))
