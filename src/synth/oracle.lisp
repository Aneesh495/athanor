;;;; oracle.lisp - Specification Verification Oracle and Counterexample Generation

(in-package #:athanor)

(defstruct (oracle (:constructor %make-oracle) (:conc-name oracle-))
  "Verification oracle that tests candidate programs against reference semantics."
  (reference-fn nil :type function)
  (domain nil :type list)
  (var-names nil :type list))

(defun make-oracle (reference-fn var-names &key (domain '(-10 -5 -2 -1 0 1 2 3 5 8 16 32 64)))
  "Construct a verification oracle from a reference function over specified input DOMAIN."
  (%make-oracle :reference-fn reference-fn
                :domain domain
                :var-names var-names))

(defun generate-test-environments (var-names domain)
  "Generate grid of test assignment environments for VAR-NAMES over values in DOMAIN."
  (let ((val-lists (make-list (length var-names) :initial-element domain)))
    (let ((tuples (cartesian-product val-lists)))
      (mapcar (lambda (tup)
                (mapcar #'cons var-names tup))
              tuples))))

(defun verify-candidate (oracle candidate)
  "Verify CANDIDATE program against ORACLE across its full test domain.
   Returns (values t nil) if valid across all tests,
   or (values nil counterexample-env) on first discrepancy."
  (let* ((ref-fn (oracle-reference-fn oracle))
         (vars (oracle-var-names oracle))
         (domain (oracle-domain oracle))
         (envs (generate-test-environments vars domain)))
    (dolist (env envs (values t nil))
      (let* ((actual (eval-term candidate env))
             (args (mapcar (lambda (v) (cdr (assoc v env))) vars))
             (expected (handler-case (apply ref-fn args) (error () :error))))
        (when (or (eq actual :error) (not (equal actual expected)))
          (return-from verify-candidate (values nil env)))))))
