;;;; test-abstract.lisp - Abstract Interpretation and Safety Verifier Tests

(in-package #:athanor-test)

(deftest test-interval-arithmetic-primitives
  (let ((i1 (make-interval 2 5))
        (i2 (make-interval 1 3)))
    ;; Addition: [2, 5] + [1, 3] = [3, 8]
    (let ((i-add (interval-add i1 i2)))
      (assert-equal (interval-lo i-add) 3.0d0)
      (assert-equal (interval-hi i-add) 8.0d0))
    ;; Subtraction: [2, 5] - [1, 3] = [-1, 4]
    (let ((i-sub (interval-sub i1 i2)))
      (assert-equal (interval-lo i-sub) -1.0d0)
      (assert-equal (interval-hi i-sub) 4.0d0))
    ;; Multiplication: [2, 5] * [1, 3] = [2, 15]
    (let ((i-mul (interval-mul i1 i2)))
      (assert-equal (interval-lo i-mul) 2.0d0)
      (assert-equal (interval-hi i-mul) 15.0d0))
    ;; Division: [2, 6] / [1, 2] = [1, 6]
    (let ((i-div (interval-div (make-interval 2 6) (make-interval 1 2))))
      (assert-equal (interval-lo i-div) 1.0d0)
      (assert-equal (interval-hi i-div) 6.0d0))))

(deftest test-division-by-zero-verification
  (let ((env (list (cons 'x (make-interval 5.0 10.0)))))
    ;; Safe: denominator in [7.0, 12.0]
    (multiple-value-bind (safe violations)
        (verify-division-by-zero-free '(/ 100 (+ x 2)) env)
      (assert-true safe)
      (assert-equal (length violations) 0))
    ;; Unsafe: denominator in [-2.0, 3.0], contains zero
    (multiple-value-bind (safe violations)
        (verify-division-by-zero-free '(/ 100 (- x 7)) env)
      (assert-false safe)
      (assert-equal (length violations) 1))))

(deftest test-interval-bounds-verification
  (let* ((env (list (cons 'x (make-interval -50.0 50.0))))
         (target (make-interval 0.0 1.0))
         (expr '(/ (+ (sin x) 1.0) 2.0)))
    (multiple-value-bind (sat iv)
        (verify-interval-bounds expr env target)
      (assert-true sat)
      (assert-equal (interval-lo iv) 0.0d0)
      (assert-equal (interval-hi iv) 1.0d0))))

(deftest test-overflow-verification
  (let ((env (list (cons 'x (make-interval 100 200)))))
    ;; 16-bit signed int max is 32767: (* x 50) is in [5000, 10000] -> safe
    (multiple-value-bind (safe iv)
        (verify-overflow-free-integer '(* x 50) env 16)
      (declare (ignore iv))
      (assert-true safe))
    ;; (* x 500) is in [50000, 100000] > 32767 -> unsafe
    (multiple-value-bind (safe iv)
        (verify-overflow-free-integer '(* x 500) env 16)
      (declare (ignore iv))
      (assert-false safe))))
