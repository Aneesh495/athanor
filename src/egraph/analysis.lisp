;;;; analysis.lisp - E-Class Analysis Lattice Framework

(in-package #:athanor)

;; Default fallback methods
(defmethod analysis-make (analysis enode eg)
  (declare (ignore analysis enode eg))
  nil)

(defmethod analysis-join (analysis data1 data2)
  (declare (ignore analysis))
  (or data1 data2))

(defmethod analysis-modify (analysis ec eg)
  (declare (ignore analysis eg))
  (eclass-data ec))

;;; Constant Folding Analysis

(defclass constant-fold-analysis ()
  ()
  (:documentation "E-class analysis that computes and propagates compile-time constant values."))

(defmethod analysis-make ((analysis constant-fold-analysis) (node enode) eg)
  (let ((op (enode-op node))
        (children (enode-children node)))
    (cond
      ;; Direct literal number
      ((numberp op) op)
      ;; Unary arithmetic operations
      ((= (length children) 1)
       (let* ((child-class (get-eclass eg (aref children 0)))
              (c-val (and child-class (eclass-data child-class))))
         (when (numberp c-val)
           (case op
             (- (- c-val))
             (abs (abs c-val))
             (sqrt (when (>= c-val 0) (sqrt c-val)))
             (sin (sin c-val))
             (cos (cos c-val))
             (exp (exp c-val))
             (log (when (> c-val 0) (log c-val)))
             (otherwise nil)))))
      ;; Binary arithmetic operations
      ((= (length children) 2)
       (let* ((c1 (get-eclass eg (aref children 0)))
              (c2 (get-eclass eg (aref children 1)))
              (v1 (and c1 (eclass-data c1)))
              (v2 (and c2 (eclass-data c2))))
         (when (and (numberp v1) (numberp v2))
           (case op
             (+ (+ v1 v2))
             (- (- v1 v2))
             (* (* v1 v2))
             (/ (unless (zerop v2) (/ v1 v2)))
             (mod (unless (zerop v2) (mod v1 v2)))
             (expt (expt v1 v2))
             (logand (and (integerp v1) (integerp v2) (logand v1 v2)))
             (logior (and (integerp v1) (integerp v2) (logior v1 v2)))
             (logxor (and (integerp v1) (integerp v2) (logxor v1 v2)))
             (ash (and (integerp v1) (integerp v2) (ash v1 v2)))
             (otherwise nil)))))
      (t nil))))

(defmethod analysis-join ((analysis constant-fold-analysis) data1 data2)
  (cond
    ((null data1) data2)
    ((null data2) data1)
    ((and (numberp data1) (numberp data2) (= data1 data2)) data1)
    (t
     ;; Inconsistent constant values indicate either numerical divergence or contradictory hypothesis
     data1)))

(defmethod analysis-modify ((analysis constant-fold-analysis) (ec eclass) eg)
  (let ((val (eclass-data ec)))
    (when (numberp val)
      ;; Add constant literal node into this class if not already present
      (let ((const-node (make-enode val #())))
        (unless (member const-node (eclass-nodes ec) :test #'enode-equal-p)
          (add-enode-to-eclass ec const-node)
          (let ((hc (egraph-hash-cons eg)))
            (hc-insert hc const-node (eclass-id ec))))))
    val))
