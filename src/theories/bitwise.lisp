;;;; bitwise.lisp - Twos-Complement Bit-Twiddling Superoptimizer Equational Rules

(in-package #:athanor)

(defun bitwise-theory ()
  "Construct the equational theory for twos-complement integer bitwise arithmetic."
  (let ((rb (make-rulebase)))
    (add-rules rb
      (list
       ;; Idempotence and Annihilation
       (defrule bit-and-self (logand ?x ?x) ?x)
       (defrule bit-ior-self (logior ?x ?x) ?x)
       (defrule bit-xor-self (logxor ?x ?x) 0)
       (defrule bit-and-zero (logand ?x 0) 0)
       (defrule bit-ior-zero (logior ?x 0) ?x)
       (defrule bit-xor-zero (logxor ?x 0) ?x)

       ;; Double Inversion and Complement Laws
       (defrule bit-not-not (lognot (lognot ?x)) ?x)
       (defrule bit-and-not (logand ?x (lognot ?x)) 0)
       (defrule bit-ior-not (logior ?x (lognot ?x)) -1)
       (defrule bit-xor-not (logxor ?x (lognot ?x)) -1)

       ;; Commutativity
       (defrule bit-and-comm (logand ?x ?y) (logand ?y ?x))
       (defrule bit-ior-comm (logior ?x ?y) (logior ?y ?x))
       (defrule bit-xor-comm (logxor ?x ?y) (logxor ?y ?x))

       ;; De Morgan Dualities
       (defrule bit-demorgan-and (lognot (logand ?x ?y)) (logior (lognot ?x) (lognot ?y)))
       (defrule bit-demorgan-ior (lognot (logior ?x ?y)) (logand (lognot ?x) (lognot ?y)))

       ;; Shift Composition and Zero Laws
       (defrule bit-shift-zero (ash ?x 0) ?x)
       (defrule bit-shift-zero-val (ash 0 ?n) 0)
       (defrule bit-shift-compose (ash (ash ?x ?a) ?b) (ash ?x (+ ?a ?b)))

       ;; Strength Reductions (multiplication to arithmetic shift)
       (defrule bit-mul-2 (* ?x 2) (ash ?x 1))
       (defrule bit-mul-4 (* ?x 4) (ash ?x 2))
       (defrule bit-mul-8 (* ?x 8) (ash ?x 3))
       (defrule bit-mul-16 (* ?x 16) (ash ?x 4))

       ;; Twos-Complement Algebraic Identities
       (defrule bit-neg-twoscomp (- ?x) (+ (lognot ?x) 1))
       (defrule bit-twoscomp-sub (- ?x 1) (+ ?x -1))
       (defrule bit-xor-diff (+ (logand ?x ?y) (logior ?x ?y)) (+ ?x ?y))
       (defrule bit-xor-to-sub (logxor ?x ?y) (- (logior ?x ?y) (logand ?x ?y)))))
    rb))
