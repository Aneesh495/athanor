;;;; test-egraph.lisp - E-Graph Kernel, Union-Find, and Congruence Closure Tests

(in-package #:athanor-test)

(deftest test-union-find-basic
  (let ((uf (make-union-find 10)))
    (dotimes (i 10) (uf-make-set uf))
    (assert-equal (uf-count uf) 10)
    (assert-equal (uf-set-count uf) 10)
    (assert-false (uf-connected-p uf 0 1))
    (uf-union uf 0 1)
    (assert-true (uf-connected-p uf 0 1))
    (assert-equal (uf-set-count uf) 9)
    (uf-union uf 2 3)
    (uf-union uf 1 3)
    (assert-true (uf-connected-p uf 0 2))
    (assert-true (uf-connected-p uf 0 3))
    (assert-false (uf-connected-p uf 0 4))))

(deftest test-enode-structural-properties
  (let ((n1 (make-enode '+ #(1 2)))
        (n2 (make-enode '+ #(1 2)))
        (n3 (make-enode '+ #(2 1))))
    (assert-true (enode-equal-p n1 n2))
    (assert-false (enode-equal-p n1 n3))
    (assert-equal (enode-hash n1) (enode-hash n2))))

(deftest test-egraph-congruence-closure
  (let ((eg (make-egraph)))
    ;; Add f(a) and f(b)
    (let* ((id-a (egraph-add-expr eg 'a))
           (id-b (egraph-add-expr eg 'b))
           (id-fa (egraph-add-expr eg '(f a)))
           (id-fb (egraph-add-expr eg '(f b))))
      (assert-false (in-same-class-p eg id-a id-b))
      (assert-false (in-same-class-p eg id-fa id-fb))
      ;; Merge a and b
      (egraph-merge eg id-a id-b)
      (egraph-rebuild eg)
      ;; Congruence closure implies f(a) == f(b)
      (assert-true (in-same-class-p eg id-a id-b))
      (assert-true (in-same-class-p eg id-fa id-fb)))))

(deftest test-pattern-matching-non-linear
  (let ((eg (make-egraph)))
    (let ((id-same (egraph-add-expr eg '(- x x)))
          (id-diff (egraph-add-expr eg '(- x y))))
      (declare (ignore id-same id-diff))
      (let ((matches (match-all-classes '(- ?a ?a) eg)))
        (assert-equal (length matches) 1)
        (let ((subst (match-subst (first matches))))
          (assert-true (assoc '?a subst)))))))

(deftest test-simple-saturation-extract
  (let ((eg (make-egraph))
        (rb (make-rulebase)))
    (add-rule rb (defrule ring-add-zero (+ ?x 0) ?x))
    (let ((root (egraph-add-expr eg '(+ (+ a 0) 0))))
      (saturate eg rb)
      (let ((best (extract-best eg root :cost-model :ast-size)))
        (assert-equal best 'a)))))
