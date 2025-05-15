;;;; sign.lisp - Sign Abstract Domain and Elementary Transfer Functions

(in-package #:athanor)

(deftype sign-t ()
  '(member :bottom :zero :pos :neg :non-neg :non-pos :top))

(defun sign-abstract (n)
  "Abstract a concrete real number into its corresponding sign domain value."
  (cond
    ((zerop n) :zero)
    ((> n 0) :pos)
    (t :neg)))

(defun sign-join (s1 s2)
  "Lattice join for sign domain."
  (cond
    ((eq s1 :bottom) s2)
    ((eq s2 :bottom) s1)
    ((eq s1 s2) s1)
    ((or (eq s1 :top) (eq s2 :top)) :top)
    ((and (or (eq s1 :zero) (eq s2 :zero)) (or (eq s1 :pos) (eq s2 :pos))) :non-neg)
    ((and (or (eq s1 :zero) (eq s2 :zero)) (or (eq s1 :neg) (eq s2 :neg))) :non-pos)
    (t :top)))

(defun sign-mul (s1 s2)
  "Sign domain multiplication transfer function."
  (cond
    ((or (eq s1 :bottom) (eq s2 :bottom)) :bottom)
    ((or (eq s1 :zero) (eq s2 :zero)) :zero)
    ((and (eq s1 :pos) (eq s2 :pos)) :pos)
    ((and (eq s1 :neg) (eq s2 :neg)) :pos)
    ((or (and (eq s1 :pos) (eq s2 :neg))
         (and (eq s1 :neg) (eq s2 :pos))) :neg)
    ((or (eq s1 :non-neg) (eq s2 :non-neg)) :top)
    (t :top)))
