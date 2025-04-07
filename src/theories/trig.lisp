;;;; trig.lisp - Trigonometric, Exponential, and Transcendental Function Transformations

(in-package #:athanor)

(defun trig-theory ()
  "Construct the equational theory for trigonometric, exponential, and transcendental identities."
  (let ((rb (make-rulebase)))
    (add-rules rb
      (list
       ;; Pythagorean Identities
       (defrule trig-pythagorean (+ (expt (sin ?x) 2) (expt (cos ?x) 2)) 1)
       (defrule trig-cos-from-sin (- 1 (expt (sin ?x) 2)) (expt (cos ?x) 2))
       (defrule trig-sin-from-cos (- 1 (expt (cos ?x) 2)) (expt (sin ?x) 2))

       ;; Basic Points of Evaluation
       (defrule trig-sin-zero (sin 0) 0)
       (defrule trig-cos-zero (cos 0) 1)
       (defrule trig-tan-zero (tan 0) 0)
       (defrule trig-exp-zero (exp 0) 1)
       (defrule trig-log-one (log 1) 0)

       ;; Odd/Even Parity Symmetries
       (defrule trig-sin-neg (sin (- ?x)) (- (sin ?x)))
       (defrule trig-cos-neg (cos (- ?x)) (cos ?x))
       (defrule trig-tan-neg (tan (- ?x)) (- (tan ?x)))

       ;; Ratio and Quotient Identities
       (defrule trig-tan-def (/ (sin ?x) (cos ?x)) (tan ?x))
       (defrule trig-sinc-def (/ (sin ?x) ?x) (sinc ?x))

       ;; Double-Angle Symmetries
       (defrule trig-sin-double (* 2 (* (sin ?x) (cos ?x))) (sin (* 2 ?x)))
       (defrule trig-cos-double (- (expt (cos ?x) 2) (expt (sin ?x) 2)) (cos (* 2 ?x)))

       ;; Exponential and Logarithm Morphisms
       (defrule trig-exp-mul (* (exp ?x) (exp ?y)) (exp (+ ?x ?y)))
       (defrule trig-exp-div (/ (exp ?x) (exp ?y)) (exp (- ?x ?y)))
       (defrule trig-log-mul (+ (log ?x) (log ?y)) (log (* ?x ?y)))
       (defrule trig-log-div (- (log ?x) (log ?y)) (log (/ ?x ?y)))
       (defrule trig-log-exp (log (exp ?x)) ?x)
       (defrule trig-exp-log (exp (log ?x)) ?x)))
    rb))
