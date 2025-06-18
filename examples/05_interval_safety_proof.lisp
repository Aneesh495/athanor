;;;; 05_interval_safety_proof.lisp - Static Safety Proofs via Abstract Interpretation

(in-package #:cl-user)

(load (merge-pathnames "../src/cli/loader.lisp" *load-truename*))

(defpackage #:athanor-example-05
  (:use #:cl #:athanor))

(in-package #:athanor-example-05)

(defun run-example ()
  (format t "========================================================================~%")
  (format t " Example 5: Formal Safety Contract Verification via Abstract Interpretation~%")
  (format t "========================================================================~%~%")

  ;; Case 1: Division-by-Zero Static Verification
  (format t "[Case 1] Static Verification of Division-by-Zero Freedom~%")
  (let ((env (list (cons 'x (make-interval 1.0 10.0)))))
    ;; Safe expression: denominator in [6.0, 15.0]
    (let ((safe-expr '(/ 10.0 (+ x 5.0))))
      (format t "Testing Safe Program: ~S with x in [1.0, 10.0]~%" safe-expr)
      (multiple-value-bind (safe-p violations)
          (verify-division-by-zero-free safe-expr env)
        (format t "Result: safe=~A, violations=~S~%" safe-p violations)
        (assert (eq safe-p t))
        (assert (null violations))))

    ;; Unsafe expression: denominator in [-4.0, 5.0], contains zero
    (let ((unsafe-expr '(/ 10.0 (- x 5.0))))
      (format t "Testing Unsafe Program: ~S with x in [1.0, 10.0]~%" unsafe-expr)
      (multiple-value-bind (safe-p violations)
          (verify-division-by-zero-free unsafe-expr env)
        (format t "Result: safe=~A, violations detected=~D~%~%" safe-p (length violations))
        (assert (null safe-p))
        (assert (= (length violations) 1)))))

  ;; Case 2: Output Range Invariant Proof
  (format t "[Case 2] Provable Value Range Invariants~%")
  (let* ((env (list (cons 'x (make-interval -100.0 100.0))))
         (target-range (make-interval 0.0 1.0))
         (normalized-expr '(/ (+ (sin x) 1.0) 2.0)))
    (format t "Proving ~S outputs in range [0.0, 1.0] for any input x...~%" normalized-expr)
    (multiple-value-bind (satisfied-p actual-iv)
        (verify-interval-bounds normalized-expr env target-range)
      (format t "Theorem Proven: ~A (Computed bounds: [~F, ~F])~%~%"
              satisfied-p (interval-lo actual-iv) (interval-hi actual-iv))
      (assert (eq satisfied-p t))))

  ;; Case 3: 16-Bit Integer Overflow Freedom
  (format t "[Case 3] Integer Overflow Freedom in DSP Pipeline~%")
  (let* ((env (list (cons 'a (make-interval 0 1000))
                    (cons 'b (make-interval 0 500))))
         (dsp-expr '(+ (* a 10) b)))
    (format t "Proving 16-bit signed int safety for ~S with a in [0, 1000], b in [0, 500]~%" dsp-expr)
    (multiple-value-bind (safe-p bounds)
        (verify-overflow-free-integer dsp-expr env 16)
      (format t "Hardware Safe: ~A (Accumulator bounds: [~F, ~F] inside [-32768, 32767])~%"
              safe-p (interval-lo bounds) (interval-hi bounds))
      (assert (eq safe-p t)))))

(run-example)
