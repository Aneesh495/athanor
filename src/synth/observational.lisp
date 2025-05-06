;;;; observational.lisp - Observational Equivalence Hashing and Signature Clustering

(in-package #:athanor)

(defun eval-term (term env)
  "Evaluate S-expression TERM in variable environment ENV alist.
   Safely traps runtime arithmetic exceptions, returning :ERROR on faults."
  (cond
    ((numberp term) term)
    ((symbolp term)
     (let ((b (assoc term env :test #'eq)))
       (if b (cdr b) term)))
    ((consp term)
     (let ((op (car term))
           (args (cdr term)))
       (handler-case
           (let ((arg-vals (mapcar (lambda (a) (eval-term a env)) args)))
             (if (member :error arg-vals :test #'eq)
                 :error
                 (case op
                   (+ (apply #'+ arg-vals))
                   (- (apply #'- arg-vals))
                   (* (apply #'* arg-vals))
                   (/ (if (zerop (second arg-vals))
                          :error
                          (/ (first arg-vals) (second arg-vals))))
                   (ash (and (integerp (first arg-vals)) (integerp (second arg-vals))
                             (ash (first arg-vals) (second arg-vals))))
                   (logand (apply #'logand arg-vals))
                   (logior (apply #'logior arg-vals))
                   (logxor (apply #'logxor arg-vals))
                   (lognot (lognot (first arg-vals)))
                   (mod (if (zerop (second arg-vals))
                            :error
                            (mod (first arg-vals) (second arg-vals))))
                   (abs (abs (first arg-vals)))
                   (min (apply #'min arg-vals))
                   (max (apply #'max arg-vals))
                   (otherwise :error))))
         (error () :error))))
    (t :error)))

(defstruct (oe-table (:constructor make-oe-table) (:conc-name oe-))
  "Observational Equivalence memoization table mapping output signatures to canonical programs."
  (table (make-hash-table :test 'equalp) :type hash-table)
  (test-inputs nil :type list))

(defun compute-signature (term test-inputs)
  "Calculate output signature vector for TERM across TEST-INPUTS."
  (let* ((len (length test-inputs))
         (sig (make-array len)))
    (loop for i from 0 below len
          for env in test-inputs
          do (setf (aref sig i) (eval-term term env)))
    sig))

(defun oe-lookup-or-insert (oe term)
  "Check whether an observationally equivalent term is already cataloged in OE.
   If present, returns (values canonical-term nil).
   If novel, inserts TERM and returns (values term t)."
  (let* ((sig (compute-signature term (oe-test-inputs oe)))
         (existing (gethash sig (oe-table oe))))
    (if existing
        (values existing nil)
        (progn
          (setf (gethash sig (oe-table oe)) term)
          (values term t)))))
