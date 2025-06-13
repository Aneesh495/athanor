;;;; 03_symbolic_deep_learning.lisp - Fused Linear Layers and Gradient Superoptimization

(in-package #:cl-user)

(load (merge-pathnames "../src/cli/loader.lisp" *load-truename*))

(defpackage #:athanor-example-03
  (:use #:cl #:athanor))

(in-package #:athanor-example-03)

(defun run-example ()
  (format t "========================================================================~%")
  (format t " Example 3: Deep Learning Computation Graph & Fused Gradient Optimization~%")
  (format t "========================================================================~%~%")

  (let ((master (combined-standard-theory)))
    ;; Case 1: GEMM kernel fusion: W*X + b -> GEMM(1, W, X, 1, b)
    (let ((expr '(+ (matmul w x) b)))
      (format t "[Input Layer] ~S~%" expr)
      (multiple-value-bind (opt rep) (saturate-expr expr master :cost-model :latency)
        (format t "[Fused BLAS Call] ~S~%~%" opt)
        (assert (equal opt '(gemm 1 w x 1 b)))))

    ;; Case 2: Analytical gradient of quadratic loss L = 1/2 * (y - y_hat)^2
    (let ((loss '(expt (- y y_hat) 2)))
      (format t "[Loss Graph] ~S~%" loss)
      (multiple-value-bind (opt raw rep)
          (differentiate-and-saturate loss 'y)
        (format t "[Raw Gradient] ~S~%" raw)
        (format t "[Superoptimized Gradient] ~S~%~%" opt)))))

(run-example)
