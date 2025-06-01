;;;; fused-grad.lisp - Differentiable S-Expression Superoptimization via Equality Saturation

(in-package #:athanor)

(defun differentiate-and-saturate (expr wrt-var &key (rulebase nil)
                                                     (cost-model :ast-size)
                                                     (max-iterations *max-iterations*)
                                                     (verbose *verbose*))
  "Differentiate EXPR analytically with respect to WRT-VAR and superoptimize the resulting gradient via E-Graphs.
   Returns (values optimized-grad raw-grad report)."
  (let* ((rb (or rulebase (combined-standard-theory)))
         (raw-grad (diff-symbolic expr wrt-var)))
    (when verbose
      (format t "[Athanor Autodiff] Raw symbolic gradient: ~S~%" raw-grad))
    (multiple-value-bind (optimized report)
        (saturate-expr raw-grad rb :cost-model cost-model :max-iterations max-iterations :verbose verbose)
      (when verbose
        (format t "[Athanor Autodiff] Saturated gradient: ~S (converged: ~A)~%"
                optimized (saturation-report-converged-p report)))
      (values optimized raw-grad report))))

(defun gradient-and-saturate (expr var-list &key (rulebase nil)
                                                 (cost-model :ast-size)
                                                 (max-iterations *max-iterations*))
  "Compute the superoptimized analytical gradient vector of EXPR across all variables in VAR-LIST."
  (let ((rb (or rulebase (combined-standard-theory))))
    (mapcar (lambda (v)
              (differentiate-and-saturate expr v
                                          :rulebase rb
                                          :cost-model cost-model
                                          :max-iterations max-iterations))
            var-list)))
