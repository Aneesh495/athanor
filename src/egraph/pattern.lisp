;;;; pattern.lisp - S-Expression Pattern Language and Compiler

(in-package #:athanor)

(defstruct (pattern (:constructor %make-pattern) (:conc-name pattern-))
  "Structured pattern for matching terms across equivalence classes."
  (ast nil :type t)
  (variables nil :type list))

(defun collect-pattern-vars (expr)
  "Collect all distinct pattern variable symbols present in EXPR."
  (let ((vars nil))
    (labels ((rec (sub)
               (cond
                 ((pattern-var-p sub)
                  (pushnew sub vars))
                 ((consp sub)
                  (rec (car sub))
                  (rec (cdr sub))))))
      (rec expr)
      (nreverse vars))))

(defun parse-pattern (expr)
  "Compile a raw S-expression pattern into a validated PATTERN structure."
  (let ((vars (collect-pattern-vars expr)))
    (%make-pattern :ast expr :variables vars)))
