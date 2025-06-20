;;;; test-logic.lisp - Relational Logic, miniKanren, CLP(FD), and Datalog Tests

(in-package #:athanor-test)

(deftest test-minikanren-basic-unification
  (let ((res1 (run 1 (q) (== q 42))))
    (assert-equal res1 '(42)))
  (let ((res2 (run 1 (q)
                (fresh (x y)
                  (== x 10)
                  (== y 20)
                  (== q (list x y))))))
    (assert-equal res2 '((10 20)))))

(deftest test-minikanren-occurs-check
  ;; Occurs check prevents cyclic infinite terms: (?x == (cons ?x nil)) fails
  (let ((res (run 1 (q)
               (fresh (x)
                 (== x (list x))
                 (== q x)))))
    (assert-equal res nil)))

(deftest test-minikanren-conde-backtracking
  (let ((res (run 3 (q)
               (conde
                 ((== q 'alpha))
                 ((== q 'beta))
                 ((== q 'gamma))))))
    (assert-equal res '(alpha beta gamma))))

(deftest test-clpfd-distinct-and-sum
  ;; Find distinct integers x, y in [1, 3] such that x + y = 4
  (let* ((vars '(x y))
         (constraints (list (in-range 'x 1 3)
                            (in-range 'y 1 3)
                            (distinct-vars '(x y))
                            (sum-constraint '(x y) 4)))
         (sols (clpfd-solve vars constraints)))
    ;; Solutions: (1, 3) and (3, 1)
    (assert-equal (length sols) 2)
    (dolist (s sols)
      (let ((x (cdr (assoc 'x s)))
            (y (cdr (assoc 'y s))))
        (assert-true (/= x y))
        (assert-equal (+ x y) 4)))))

(deftest test-datalog-transitive-closure
  (let ((eng (make-datalog-engine)))
    ;; Directed graph edges: 1->2, 2->3, 3->4
    (datalog-assert eng 'edge '(1 2))
    (datalog-assert eng 'edge '(2 3))
    (datalog-assert eng 'edge '(3 4))

    ;; Rules:
    ;; path(?x, ?y) :- edge(?x, ?y).
    ;; path(?x, ?z) :- path(?x, ?y), edge(?y, ?z).
    (datalog-rule eng '(path ?x ?y) '((edge ?x ?y)))
    (datalog-rule eng '(path ?x ?z) '((path ?x ?y) (edge ?y ?z)))

    ;; Fixpoint closure
    (let ((derived (datalog-fixpoint eng)))
      (assert-true (> derived 0))
      ;; Check reachable paths from 1
      (let ((paths-from-1 (datalog-query eng '(path 1 ?to))))
        ;; 1 can reach 2, 3, 4
        (assert-equal (length paths-from-1) 3)
        (let ((destinations (mapcar (lambda (match)
                                      (cdr (assoc '?to (cdr match))))
                                    paths-from-1)))
          (assert-true (member 2 destinations))
          (assert-true (member 3 destinations))
          (assert-true (member 4 destinations)))))))
