;;;; bottom-up.lisp - Component-Based Bottom-Up Enumerative Program Synthesis

(in-package #:athanor)

(defun satisfies-examples-p (term examples)
  "Return T if TERM evaluates to the expected output for all input-output EXAMPLES."
  (every (lambda (ex)
           (let* ((env (car ex))
                  (expected (cdr ex))
                  (actual (eval-term term env)))
             (and (not (eq actual :error))
                  (equal actual expected))))
         examples))

(defun cartesian-product (lists)
  "Compute the Cartesian product of a list of lists."
  (if (null lists)
      (list nil)
      (let ((rest-prod (cartesian-product (cdr lists)))
            (first-list (car lists)))
        (mapcan (lambda (x)
                  (mapcar (lambda (p) (cons x p)) rest-prod))
                first-list))))

(defun bottom-up-synthesize (grammar examples &key (max-depth *synthesis-max-depth*)
                                                   (timeout-seconds *synthesis-timeout-seconds*))
  "Synthesize an S-expression satisfying EXAMPLES using bottom-up enumerative search with OE pruning."
  (let* ((test-inputs (mapcar #'car examples))
         (oe (make-oe-table :test-inputs test-inputs))
         (term-bank (make-hash-table :test 'eq))
         (start-time (get-internal-real-time)))

    ;; Level 1: Enumerate terminals (constants and variables)
    (let ((level-1 nil))
      (maphash (lambda (lhs prods)
                 (dolist (p prods)
                   (when (null (prod-rhs-types p))
                     (let ((term (prod-op p)))
                       (multiple-value-bind (canon novel-p)
                           (oe-lookup-or-insert oe term)
                         (declare (ignore canon))
                         (when novel-p
                           (when (satisfies-examples-p term examples)
                             (return-from bottom-up-synthesize term))
                           (push term (gethash lhs term-bank))
                           (push term level-1)))))))
               (grammar-productions grammar)))

    ;; Iterative deepening by term tree depth
    (loop for depth from 2 to max-depth
          do (let ((elapsed (/ (- (get-internal-real-time) start-time)
                               (float internal-time-units-per-second 1.0))))
               (when (> elapsed timeout-seconds)
                 (error 'synthesis-exhausted-error :specification examples))

               (let ((new-terms-at-depth nil))
                 (maphash (lambda (lhs prods)
                            (declare (ignore lhs))
                            (dolist (p prods)
                              (when (prod-rhs-types p)
                                (let* ((op (prod-op p))
                                       (arg-types (prod-rhs-types p))
                                       (arg-lists (mapcar (lambda (tp) (gethash tp term-bank))
                                                          arg-types)))
                                  (when (every #'identity arg-lists)
                                    (let ((combos (cartesian-product arg-lists)))
                                      (dolist (args combos)
                                        (let ((term (cons op args)))
                                          (multiple-value-bind (canon novel-p)
                                              (oe-lookup-or-insert oe term)
                                            (declare (ignore canon))
                                            (when novel-p
                                              (when (satisfies-examples-p term examples)
                                                (return-from bottom-up-synthesize term))
                                              (push term new-terms-at-depth)))))))))))
                          (grammar-productions grammar))

                 (unless new-terms-at-depth
                   (return))

                 (dolist (term new-terms-at-depth)
                   (push term (gethash 'expr term-bank))))))

    (error 'synthesis-exhausted-error :specification examples)))
