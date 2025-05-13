;;;; cegis.lisp - Counterexample-Guided Inductive Synthesis (CEGIS) Engine

(in-package #:athanor)

(defun cegis-synthesize (grammar oracle &key (max-rounds 12)
                                             (max-depth *synthesis-max-depth*)
                                             (verbose *verbose*))
  "Synthesize a formally verified program using Counterexample-Guided Inductive Synthesis."
  (declare (type grammar grammar)
           (type oracle oracle)
           (type fixnum max-rounds max-depth))
  (let* ((vars (oracle-var-names oracle))
         (ref-fn (oracle-reference-fn oracle))
         ;; Initialize with two initial seed examples from domain
         (initial-env-1 (mapcar (lambda (v) (cons v 1)) vars))
         (initial-env-2 (mapcar (lambda (v) (cons v 2)) vars))
         (examples
           (list (cons initial-env-1 (apply ref-fn (mapcar #'cdr initial-env-1)))
                 (cons initial-env-2 (apply ref-fn (mapcar #'cdr initial-env-2))))))

    (loop for round from 1 to max-rounds
          do (when verbose
               (format t "[CEGIS Round ~2D] Current counterexamples count: ~D~%"
                       round (length examples)))
             ;; Step 1: Synthesize candidate program satisfying all current examples
             (let ((candidate (bottom-up-synthesize grammar examples :max-depth max-depth)))
               (when verbose
                 (format t "[CEGIS Candidate] ~S~%" candidate))

               ;; Step 2: Query verification oracle for full-domain validity
               (multiple-value-bind (verified-p cex-env)
                   (verify-candidate oracle candidate)
                 (if verified-p
                     ;; Program proven correct across entire specification domain
                     (progn
                       (when verbose
                         (format t "[CEGIS Success] Formally verified in round ~D: ~S~%"
                                 round candidate))
                       (return-from cegis-synthesize candidate))
                     ;; Discovered counterexample: refine example set and iterate
                     (let* ((args (mapcar (lambda (v) (cdr (assoc v cex-env))) vars))
                            (expected-out (apply ref-fn args)))
                       (when verbose
                         (format t "[CEGIS Counterexample] Input: ~S | Expected: ~S~%"
                                 cex-env expected-out))
                       (push (cons cex-env expected-out) examples))))))

    (error 'synthesis-exhausted-error :specification examples)))
