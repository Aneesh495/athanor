;;;; test-synthesis.lisp - Inductive Program Synthesis, OE, and CEGIS Tests

(in-package #:athanor-test)

(deftest test-grammar-construction
  (let ((g (standard-arithmetic-grammar '(x y) '(0 1 2))))
    (assert-true (grammar-p g))
    (assert-true (member 'x (grammar-variables g)))
    (assert-true (member 'y (grammar-variables g)))))

(deftest test-observational-equivalence-cache
  (let* ((inputs '(((x . 1)) ((x . 2)) ((x . 3))))
         (oe (make-oe-table :test-inputs inputs)))
    ;; (+ x 0) and x evaluate to identical output vectors #(1 2 3)
    (multiple-value-bind (c1 novel1) (oe-lookup-or-insert oe 'x)
      (declare (ignore c1))
      (assert-true novel1))
    (multiple-value-bind (c2 novel2) (oe-lookup-or-insert oe '(+ x 0))
      (assert-equal c2 'x)
      (assert-false novel2))))

(deftest test-bottom-up-synthesizer
  (let* ((g (standard-arithmetic-grammar '(x) '(1 2)))
         (spec (list (cons '((x . 1)) 2)
                     (cons '((x . 2)) 4)
                     (cons '((x . 3)) 6)))
         (prog (bottom-up-synthesize g spec :max-depth 3)))
    (assert-true (member prog '((ash x 1) (* x 2) (+ x x)) :test #'equal))))

(deftest test-cegis-closed-loop-synthesis
  (let* ((g (standard-arithmetic-grammar '(x) '(0 1 2)))
         (oracle (make-oracle (lambda (x) (* x 2))
                              '(x)
                              :domain '(0 1 2 3 4 5)))
         (prog (cegis-synthesize g oracle :max-depth 3)))
    (assert-true (member prog '((ash x 1) (* x 2) (+ x x)) :test #'equal))))
