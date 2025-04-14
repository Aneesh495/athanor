;;;; rules.lisp - Declarative Equational Rewrite Rule Specifications and Collections

(in-package #:athanor)

(defstruct (rule (:constructor %make-rule) (:conc-name rule-))
  "A bidirectional or directional equational rewrite rule: LHS ~> RHS."
  (name nil :type symbol)
  (lhs nil :type t)
  (rhs nil :type t)
  (condition nil :type (or null function)))

(defun make-rule (name lhs rhs &optional condition)
  "Create a rewrite rule with a name, left-hand side pattern, right-hand side pattern, and optional predicate."
  (%make-rule :name name
              :lhs (if (pattern-p lhs) lhs (parse-pattern lhs))
              :rhs rhs
              :condition condition))

(defmacro defrule (name lhs rhs &key (when nil))
  "Convenience macro for defining a declarative rewrite rule with optional guard condition."
  `(make-rule ',name ',lhs ',rhs ,when))

(defstruct (rulebase (:constructor make-rulebase) (:conc-name rulebase-))
  "A named collection of rewrite rules that form an equational theory."
  (rules nil :type list))

(defun add-rule (rb rule)
  "Append RULE to RULEBASE."
  (declare (type rulebase rb)
           (type rule rule))
  (push rule (rulebase-rules rb))
  rb)

(defun add-rules (rb rules-list)
  "Append multiple rules to RULEBASE."
  (dolist (r rules-list rb)
    (add-rule rb r)))

(defparameter *max-matches-per-rule* 40
  "Maximum number of matches permitted for a single rewrite rule per saturation iteration.")

(defun apply-rules-once (rb eg)
  "Execute a single matching and substitution round for all rules in RB against EG.
   Returns the number of new equality unions enacted."
  (declare (type rulebase rb)
           (type egraph eg)
           (optimize (speed 3) (safety 1)))
  (let ((matches-to-apply nil)
        (merges-count 0))
    ;; Phase 1: Search and match all rules (read-only against clean e-graph)
    (dolist (r (rulebase-rules rb))
      (let* ((lhs (rule-lhs r))
             (rhs (rule-rhs r))
             (guard (rule-condition r))
             (rule-matches (match-all-classes lhs eg))
             (matched 0))
        (dolist (m rule-matches)
          (when (< matched *max-matches-per-rule*)
            (let ((subst (match-subst m))
                  (class-id (match-class-id m)))
              (when (or (null guard) (funcall guard subst eg))
                (push (list rhs subst class-id) matches-to-apply)
                (incf matched)))))))

    ;; Phase 2: Instantiate right-hand sides and perform equality unions
    (dolist (entry matches-to-apply)
      (let* ((rhs-ast (first entry))
             (subst (second entry))
             (target-class-id (third entry))
             (rhs-class-id (apply-substitution rhs-ast subst eg)))
        (unless (in-same-class-p eg target-class-id rhs-class-id)
          (egraph-merge eg target-class-id rhs-class-id)
          (incf merges-count))))

    merges-count))
