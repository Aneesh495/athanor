;;;; ring.lisp - Commutative Ring and Polynomial Arithmetic Rewriting Theories

(in-package #:athanor)

(defun ring-theory ()
  "Construct the equational theory for commutative rings with unit."
  (let ((rb (make-rulebase)))
    (add-rules rb
      (list
       ;; Additive Identity & Inverses
       (defrule ring-add-zero-r (+ ?x 0) ?x)
       (defrule ring-add-zero-l (+ 0 ?x) ?x)
       (defrule ring-sub-zero (- ?x 0) ?x)
       (defrule ring-zero-sub (- 0 ?x) (- ?x))
       (defrule ring-sub-self (- ?x ?x) 0)
       (defrule ring-add-neg (+ ?x (- ?x)) 0)
       (defrule ring-neg-neg (- (- ?x)) ?x)

       ;; Multiplicative Identity & Annihilation
       (defrule ring-mul-one-r (* ?x 1) ?x)
       (defrule ring-mul-one-l (* 1 ?x) ?x)
       (defrule ring-mul-zero-r (* ?x 0) 0)
       (defrule ring-mul-zero-l (* 0 ?x) 0)

       ;; Division Identities (when non-zero)
       (defrule ring-div-one (/ ?x 1) ?x)
       (defrule ring-div-self (/ ?x ?x) 1
         :when (lambda (subst eg)
                 (let* ((binding (assoc '?x subst))
                        (cid (and binding (cdr binding)))
                        (ec (and cid (get-eclass eg cid))))
                   (and ec (not (member 0 (eclass-nodes ec) :key #'enode-op :test #'equal))))))

       ;; Commutativity
       (defrule ring-add-comm (+ ?x ?y) (+ ?y ?x))
       (defrule ring-mul-comm (* ?x ?y) (* ?y ?x))

       ;; Canonical Associativity
       (defrule ring-add-assoc (+ (+ ?x ?y) ?z) (+ ?x (+ ?y ?z)))
       (defrule ring-mul-assoc (* (* ?x ?y) ?z) (* ?x (* ?y ?z)))

       ;; Distributivity and Factoring
       (defrule ring-distrib (* ?x (+ ?y ?z)) (+ (* ?x ?y) (* ?x ?z)))
       (defrule ring-factor (+ (* ?x ?y) (* ?x ?z)) (* ?x (+ ?y ?z)))
       (defrule ring-sub-distrib (* ?x (- ?y ?z)) (- (* ?x ?y) (* ?x ?z)))

       ;; Exponential Powers
       (defrule ring-expt-zero (expt ?x 0) 1)
       (defrule ring-expt-one (expt ?x 1) ?x)
       (defrule ring-expt-mul (* ?x ?x) (expt ?x 2))
       (defrule ring-expt-add (* (expt ?x ?m) (expt ?x ?n)) (expt ?x (+ ?m ?n)))))
    rb))
