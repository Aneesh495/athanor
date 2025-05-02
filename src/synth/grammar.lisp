;;;; grammar.lisp - Context-Free Grammar for S-Expression Program Synthesis

(in-package #:athanor)

(defstruct (production (:constructor make-production) (:conc-name prod-))
  "A context-free production rule: LHS -> (Operator RHS_1 RHS_2 ...)"
  (lhs nil :type symbol)
  (op nil :type t)
  (rhs-types nil :type list)
  (cost 1 :type fixnum))

(defstruct (grammar (:constructor make-grammar) (:conc-name grammar-))
  "Context-free grammar defining the syntax space for program synthesis."
  (productions (make-hash-table :test 'eq) :type hash-table)
  (terminals nil :type list)
  (variables nil :type list))

(defun add-production (grammar lhs op rhs-types &key (cost 1))
  "Add production LHS -> (OP RHS-TYPES...) with associated structural cost to GRAMMAR."
  (declare (type grammar grammar)
           (type symbol lhs)
           (type t op)
           (type list rhs-types)
           (type fixnum cost))
  (let ((prod (make-production :lhs lhs :op op :rhs-types rhs-types :cost cost)))
    (push prod (gethash lhs (grammar-productions grammar)))
    grammar))

(defun add-terminal (grammar lhs val &key (cost 1))
  "Add atomic literal or constant production LHS -> VAL to GRAMMAR."
  (add-production grammar lhs val nil :cost cost))

(defun add-variable (grammar lhs var-sym &key (cost 1))
  "Add input parameter variable symbol to GRAMMAR."
  (push var-sym (grammar-variables grammar))
  (add-terminal grammar lhs var-sym :cost cost))

(defun standard-arithmetic-grammar (var-names &optional (constants '(0 1 2)))
  "Construct a standard arithmetic grammar over VAR-NAMES and integer CONSTANTS."
  (let ((g (make-grammar)))
    ;; Terminals: constants and input variables
    (dolist (c constants)
      (add-terminal g 'expr c :cost 1))
    (dolist (v var-names)
      (add-variable g 'expr v :cost 1))

    ;; Binary arithmetic operators
    (add-production g 'expr '+ '(expr expr) :cost 1)
    (add-production g 'expr '- '(expr expr) :cost 1)
    (add-production g 'expr '* '(expr expr) :cost 2)
    (add-production g 'expr 'ash '(expr expr) :cost 1)
    (add-production g 'expr 'logand '(expr expr) :cost 1)
    (add-production g 'expr 'logior '(expr expr) :cost 1)
    (add-production g 'expr 'logxor '(expr expr) :cost 1)

    ;; Unary operators
    (add-production g 'expr '- '(expr) :cost 1)
    (add-production g 'expr 'lognot '(expr) :cost 1)
    g))
