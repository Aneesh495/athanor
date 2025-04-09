;;;; boolean.lisp - Propositional Boolean Calculus and Equational Logic Normalization

(in-package #:athanor)

(defun boolean-theory ()
  "Construct the equational theory for propositional boolean algebra and logic simplification."
  (let ((rb (make-rulebase)))
    (add-rules rb
      (list
       ;; Identity and Annihilation
       (defrule bool-and-true (and ?x t) ?x)
       (defrule bool-and-false (and ?x nil) nil)
       (defrule bool-or-true (or ?x t) t)
       (defrule bool-or-false (or ?x nil) ?x)

       ;; Idempotence and Complement
       (defrule bool-and-self (and ?x ?x) ?x)
       (defrule bool-or-self (or ?x ?x) ?x)
       (defrule bool-and-not (and ?x (not ?x)) nil)
       (defrule bool-or-not (or ?x (not ?x)) t)

       ;; Involution and Commutativity
       (defrule bool-not-not (not (not ?x)) ?x)
       (defrule bool-and-comm (and ?x ?y) (and ?y ?x))
       (defrule bool-or-comm (or ?x ?y) (or ?y ?x))

       ;; De Morgan Laws
       (defrule bool-demorgan-and (not (and ?x ?y)) (or (not ?x) (not ?y)))
       (defrule bool-demorgan-or (not (or ?x ?y)) (and (not ?x) (not ?y)))

       ;; Logical Connective Desugaring
       (defrule bool-implies (=> ?p ?q) (or (not ?p) ?q))
       (defrule bool-iff (<=> ?p ?q) (and (or (not ?p) ?q) (or (not ?q) ?p)))))
    rb))
