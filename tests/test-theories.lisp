;;;; test-theories.lisp - Equational Theories and Domain Rewrite Tests

(in-package #:athanor-test)

(deftest test-ring-theory-cancellations
  (let ((rb (ring-theory)))
    (multiple-value-bind (opt1 rep1)
        (saturate-expr '(+ x 0) rb)
      (declare (ignore rep1))
      (assert-equal opt1 'x))
    (multiple-value-bind (opt2 rep2)
        (saturate-expr '(* x 0) rb)
      (declare (ignore rep2))
      (assert-equal opt2 0))
    (multiple-value-bind (opt3 rep3)
        (saturate-expr '(* x 1) rb)
      (declare (ignore rep3))
      (assert-equal opt3 'x))
    (multiple-value-bind (opt4 rep4)
        (saturate-expr '(- x x) rb)
      (declare (ignore rep4))
      (assert-equal opt4 0))))

(deftest test-bitwise-theory-strength-reduction
  (let ((rb (bitwise-theory)))
    ;; Multiplication by 8 is replaced by shift left 3
    (multiple-value-bind (opt rep)
        (saturate-expr '(* x 8) rb :cost-model :latency)
      (declare (ignore rep))
      (assert-equal opt '(ash x 3)))
    ;; XOR self cancellation
    (multiple-value-bind (opt rep)
        (saturate-expr '(logxor a a) rb)
      (declare (ignore rep))
      (assert-equal opt 0))
    ;; Shift fusion with combined theory and constant folding
    (multiple-value-bind (opt rep)
        (saturate-expr '(ash (ash x 2) 3) (combined-standard-theory)
                       :analysis (make-constant-fold-analysis))
      (declare (ignore rep))
      (assert-equal opt '(ash x 5)))))

(deftest test-trig-pythagorean-identity
  (let ((rb (trig-theory)))
    (multiple-value-bind (opt rep)
        (saturate-expr '(+ (expt (sin theta) 2) (expt (cos theta) 2)) rb)
      (declare (ignore rep))
      (assert-equal opt 1))))

(deftest test-tensor-blas-gemm-fusion
  (let ((rb (tensor-theory)))
    (multiple-value-bind (opt rep)
        (saturate-expr '(+ (matmul w x) b) rb :cost-model :latency)
      (declare (ignore rep))
      (assert-equal opt '(gemm 1 w x 1 b)))))

(deftest test-float-stabilize-accuracies
  (let ((rb (float-stabilize-theory)))
    (multiple-value-bind (opt1 rep1)
        (saturate-expr '(log (+ 1 eps)) rb)
      (declare (ignore rep1))
      (assert-equal opt1 '(log1p eps)))
    (multiple-value-bind (opt2 rep2)
        (saturate-expr '(- (exp eps) 1) rb)
      (declare (ignore rep2))
      (assert-equal opt2 '(expm1 eps)))))
