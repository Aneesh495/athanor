;;;; domain.lisp - Abstract Domain Protocol and Lattice Primitives (Cousot & Cousot)

(in-package #:athanor)

;;; Abstract Domain Protocol Generics

(defgeneric domain-top (domain)
  (:documentation "The top element (universal set / most general property) of the abstract lattice."))

(defgeneric domain-bottom (domain)
  (:documentation "The bottom element (empty set / unreachable state) of the abstract lattice."))

(defgeneric domain-join (domain d1 d2)
  (:documentation "Lattice join (least upper bound): computes sound union of abstract states."))

(defgeneric domain-meet (domain d1 d2)
  (:documentation "Lattice meet (greatest lower bound): computes conjunction of abstract states."))

(defgeneric domain-leq (domain d1 d2)
  (:documentation "Partial ordering test: returns T if state D1 is soundly subsumed by state D2."))

(defgeneric domain-widen (domain d1 d2)
  (:documentation "Widening operator to ensure finite fixpoint convergence over infinite-height lattices."))

(defgeneric domain-narrow (domain d1 d2)
  (:documentation "Narrowing operator to recover precision after widening convergence."))
