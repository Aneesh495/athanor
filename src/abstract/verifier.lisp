;;;; verifier.lisp - Formal Safety Contract Verification via Abstract Interpretation

(in-package #:athanor)

(defun verify-division-by-zero-free (expr env)
  "Statically verify that no division operations in EXPR can divide by zero under abstract input ENV.
   Returns (values safe-p violating-subexpressions)."
  (let ((violations nil))
    (labels ((check-tree (sub)
               (when (consp sub)
                 (let ((op (car sub))
                       (args (cdr sub)))
                   (when (and (op-equal-p op '/) (>= (length args) 2))
                     (let* ((denom (second args))
                            (denom-iv (abstract-eval denom env)))
                       (when (interval-contains-zero-p denom-iv)
                         (push (cons denom denom-iv) violations))))
                   (dolist (a args)
                     (check-tree a))))))
      (check-tree expr)
      (values (null violations) (nreverse violations)))))

(defun verify-interval-bounds (expr env target-interval)
  "Statically prove that output of EXPR in abstract environment ENV is bounded within TARGET-INTERVAL.
   Returns (values satisfied-p computed-interval)."
  (let ((actual-iv (abstract-eval expr env)))
    (let ((satisfied (and (>= (interval-lo actual-iv) (interval-lo target-interval))
                          (<= (interval-hi actual-iv) (interval-hi target-interval)))))
      (values satisfied actual-iv))))

(defun verify-overflow-free-integer (expr env bit-width)
  "Statically prove that integer computation EXPR cannot overflow a twos-complement BIT-WIDTH integer.
   Returns (values safe-p computed-bounds)."
  (let* ((limit (expt 2 (1- bit-width)))
         (int-min (- limit))
         (int-max (1- limit))
         (target (make-interval int-min int-max)))
    (verify-interval-bounds expr env target)))
