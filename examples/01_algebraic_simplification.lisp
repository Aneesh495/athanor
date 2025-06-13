;;;; 01_algebraic_simplification.lisp - High-Order Polynomial and Trigonometric Reduction

(in-package #:cl-user)

(load (merge-pathnames "../src/cli/loader.lisp" *load-truename*))

(defpackage #:athanor-example-01
  (:use #:cl #:athanor))

(in-package #:athanor-example-01)

(defun run-example ()
  (format t "========================================================================~%")
  (format t " Example 1: Algebraic Simplification via Equality Saturation~%")
  (format t "========================================================================~%~%")

  (let ((master (combined-standard-theory)))
    ;; Case 1: Pythagorean trigonometric identity
    (let ((expr '(+ (expt (sin x) 2) (expt (cos x) 2))))
      (format t "[Input 1] ~S~%" expr)
      (multiple-value-bind (opt rep) (saturate-expr expr master)
        (format t "[Output 1] ~S (converged: ~A, nodes: ~D)~%~%"
                opt (saturation-report-converged-p rep) (saturation-report-nodes rep))
        (assert (equal opt 1))))

    ;; Case 2: Multi-step polynomial zero cancellation
    (let ((expr '(* (+ a (- a)) (* b 1))))
      (format t "[Input 2] ~S~%" expr)
      (multiple-value-bind (opt rep) (saturate-expr expr master)
        (format t "[Output 2] ~S (nodes: ~D)~%~%" opt (saturation-report-nodes rep))
        (assert (equal opt 0))))

    ;; Case 3: Rational difference of squares
    (let ((expr '(* (+ x y) (- x y))))
      (format t "[Input 3] ~S~%" expr)
      (multiple-value-bind (opt rep) (saturate-expr expr master)
        (format t "[Output 3] ~S (nodes: ~D)~%~%" opt (saturation-report-nodes rep))))))

(run-example)
