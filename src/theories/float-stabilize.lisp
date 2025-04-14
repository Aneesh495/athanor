;;;; float-stabilize.lisp - Numerical Accuracy, Cancellation Avoidance, and Theory Bundling

(in-package #:athanor)

(defun float-stabilize-theory ()
  "Construct equational rules for preventing catastrophic cancellation and enhancing floating-point stability."
  (let ((rb (make-rulebase)))
    (add-rules rb
      (list
       ;; Square Root Difference Rationalization (avoids subtractive cancellation when x >> 1)
       (defrule num-sqrt-diff-rat (- (sqrt (+ ?x 1)) (sqrt ?x))
         (/ 1 (+ (sqrt (+ ?x 1)) (sqrt ?x))))

       ;; Accurate Small-Value Function Replacements
       (defrule num-log-1p (log (+ 1 ?x)) (log1p ?x))
       (defrule num-exp-m1 (- (exp ?x) 1) (expm1 ?x))

       ;; Difference of Squares Factoring
       (defrule num-diff-squares (- (expt ?a 2) (expt ?b 2))
         (* (- ?a ?b) (+ ?a ?b)))

       ;; Rational Fraction Normalizations
       (defrule num-div-div (/ (/ ?a ?b) ?c) (/ ?a (* ?b ?c)))
       (defrule num-div-mul (/ ?a (/ ?b ?c)) (/ (* ?a ?c) ?b))

       ;; Horner's Form Polynomial Transformation (numerically superior to direct power sum)
       (defrule num-horner-quad (+ (+ (* ?a (expt ?x 2)) (* ?b ?x)) ?c)
         (+ (* (+ (* ?a ?x) ?b) ?x) ?c))))
    rb))

(defun combined-standard-theory ()
  "Assemble a comprehensive equational super-theory combining ring, bitwise, trig, tensor, and numerical rules."
  (let ((master (make-rulebase)))
    (dolist (theory (list (ring-theory)
                          (bitwise-theory)
                          (trig-theory)
                          (tensor-theory)
                          (boolean-theory)
                          (float-stabilize-theory)))
      (add-rules master (rulebase-rules theory)))
    master))
