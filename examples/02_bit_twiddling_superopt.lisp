;;;; 02_bit_twiddling_superopt.lisp - Twos-Complement Bit-Twiddling Superoptimizer

(in-package #:cl-user)

(load (merge-pathnames "../src/cli/loader.lisp" *load-truename*))

(defpackage #:athanor-example-02
  (:use #:cl #:athanor))

(in-package #:athanor-example-02)

(defun run-example ()
  (format t "========================================================================~%")
  (format t " Example 2: Bit-Twiddling Superoptimizer (Hacker's Delight)~%")
  (format t "========================================================================~%~%")

  (let ((master (combined-standard-theory)))
    ;; Case 1: Multiplier strength reduction under hardware latency model
    (let ((expr '(* x 16)))
      (format t "[Input 1] Multiplication: ~S~%" expr)
      (multiple-value-bind (opt rep) (saturate-expr expr master :cost-model :latency)
        (format t "[Superoptimized 1] ~S (reduced to ALU shift, latency 1)~%~%" opt)
        (assert (equal opt '(ash x 4)))))

    ;; Case 2: Double bitwise inversion cancellation
    (let ((expr '(lognot (lognot (logand a b)))))
      (format t "[Input 2] Nested Inversion: ~S~%" expr)
      (multiple-value-bind (opt rep) (saturate-expr expr master)
        (format t "[Superoptimized 2] ~S~%~%" opt)
        (assert (equal opt '(logand a b)))))

    ;; Case 3: XOR identity simplification
    (let ((expr '(logxor x x)))
      (format t "[Input 3] XOR Self: ~S~%" expr)
      (multiple-value-bind (opt rep) (saturate-expr expr master)
        (format t "[Superoptimized 3] ~S~%~%" opt)
        (assert (equal opt 0))))))

(run-example)
