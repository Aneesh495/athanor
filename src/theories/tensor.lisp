;;;; tensor.lisp - Tensor Contraction, Linear Algebra, and BLAS Fusion Rewrites

(in-package #:athanor)

(defun tensor-theory ()
  "Construct the equational theory for tensor contractions and matrix calculus."
  (let ((rb (make-rulebase)))
    (add-rules rb
      (list
       ;; Transposition Invariants
       (defrule tensor-trans-involution (transpose (transpose ?a)) ?a)
       (defrule tensor-trans-add (transpose (+ ?a ?b)) (+ (transpose ?a) (transpose ?b)))
       (defrule tensor-trans-mul (transpose (matmul ?a ?b)) (matmul (transpose ?b) (transpose ?a)))

       ;; Matrix Multiplication Properties
       (defrule tensor-matmul-assoc (matmul (matmul ?a ?b) ?c) (matmul ?a (matmul ?b ?c)))
       (defrule tensor-matmul-id-r (matmul ?a eye) ?a)
       (defrule tensor-matmul-id-l (matmul eye ?a) ?a)
       (defrule tensor-matmul-zero-r (matmul ?a zero-mat) zero-mat)
       (defrule tensor-matmul-zero-l (matmul zero-mat ?a) zero-mat)

       ;; Distributivity Over Addition
       (defrule tensor-distrib-r (matmul ?a (+ ?b ?c)) (+ (matmul ?a ?b) (matmul ?a ?c)))
       (defrule tensor-distrib-l (matmul (+ ?a ?b) ?c) (+ (matmul ?a ?c) (matmul ?b ?c)))

       ;; Trace Function Invariants
       (defrule tensor-trace-trans (trace (transpose ?a)) (trace ?a))
       (defrule tensor-trace-add (trace (+ ?a ?b)) (+ (trace ?a) (trace ?b)))
       (defrule tensor-trace-cyclic (trace (matmul ?a ?b)) (trace (matmul ?b ?a)))

       ;; Kernel Fusion to Standard BLAS Call (GEMM: alpha*A*B + beta*C)
       (defrule tensor-fuse-gemm (+ (matmul ?w ?x) ?b) (gemm 1 ?w ?x 1 ?b))
       (defrule tensor-fuse-gemm-sub (- (matmul ?w ?x) ?b) (gemm 1 ?w ?x -1 ?b))))
    rb))
