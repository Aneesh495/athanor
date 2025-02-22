;;;; types.lisp - Core Types, Conditions, and Fundamental Data Definitions

(in-package #:athanor)

;;; Core Types

(deftype e-id ()
  "E-class identifier: non-negative integer representation."
  '(integer 0 *))

(deftype cost-t ()
  "Numerical evaluation metric used by extraction cost models."
  '(real 0 *))

;;; Error Conditions

(define-condition athanor-error (error)
  ((message :initarg :message :reader error-message :initform "Unspecified Athanor kernel error."))
  (:report (lambda (condition stream)
             (format stream "[Athanor Error] ~A" (error-message condition)))))

(define-condition cycle-detected-error (athanor-error)
  ((cycle-node :initarg :cycle-node :reader cycle-node :initform nil))
  (:report (lambda (condition stream)
             (format stream "[Athanor Error] Cycle detected during extraction at node: ~S"
                     (cycle-node condition)))))

(define-condition saturation-timeout-error (athanor-error)
  ((elapsed-seconds :initarg :elapsed-seconds :reader elapsed-seconds :initform 0.0))
  (:report (lambda (condition stream)
             (format stream "[Athanor Error] Saturation timed out after ~F seconds."
                     (elapsed-seconds condition)))))

(define-condition node-limit-exceeded-error (athanor-error)
  ((current-nodes :initarg :current-nodes :reader current-nodes :initform 0)
   (limit :initarg :limit :reader node-limit :initform 0))
  (:report (lambda (condition stream)
             (format stream "[Athanor Error] E-node limit exceeded: ~D nodes allocated (limit is ~D)."
                     (current-nodes condition) (node-limit condition)))))

(define-condition unification-failure (athanor-error)
  ((term1 :initarg :term1 :reader fail-term1 :initform nil)
   (term2 :initarg :term2 :reader fail-term2 :initform nil))
  (:report (lambda (condition stream)
             (format stream "[Athanor Error] Unification failure between ~S and ~S."
                     (fail-term1 condition) (fail-term2 condition)))))

(define-condition synthesis-exhausted-error (athanor-error)
  ((specification :initarg :specification :reader fail-spec :initform nil))
  (:report (lambda (condition stream)
             (format stream "[Athanor Error] Synthesis space exhausted without finding program for specification: ~S"
                     (fail-spec condition)))))

(define-condition abstract-domain-error (athanor-error)
  ((operation :initarg :operation :reader domain-op :initform nil)
   (operands :initarg :operands :reader domain-operands :initform nil))
  (:report (lambda (condition stream)
             (format stream "[Athanor Error] Abstract domain evaluation error in ~A with operands ~S."
                     (domain-op condition) (domain-operands condition)))))

;;; Utility Hashing Primitives

(declaim (inline mix-hash))
(defun mix-hash (h1 h2)
  "Murmur-style fast hash combination of two integer hash values."
  (declare (type fixnum h1 h2)
           (optimize (speed 3) (safety 0)))
  (let ((m (logand (+ (* h1 31) h2) #x1FFFFFFF)))
    m))

(defun sexpr-equal-p (x y)
  "Deep structural equality for s-expressions handling symbols, numbers, and cons cells."
  (cond
    ((equal x y) t)
    ((and (consp x) (consp y))
     (and (sexpr-equal-p (car x) (car y))
          (sexpr-equal-p (cdr x) (cdr y))))
    (t nil)))
