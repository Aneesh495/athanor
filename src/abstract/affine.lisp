;;;; affine.lisp - Affine Arithmetic for Correlated Uncertainty and Error Tracking

(in-package #:athanor)

(defparameter *noise-symbol-counter* 0
  "Monotonically increasing generator for shared noise symbols in affine arithmetic.")

(defstruct (affine-form (:constructor %make-affine-form) (:conc-name affine-))
  "Affine form x = x_0 + sum(x_i * epsilon_i) where each epsilon_i in [-1, +1]."
  (c0 0.0d0 :type double-float)
  (terms nil :type list))

(defun make-affine-form (c0 &optional terms)
  "Create an affine form with central value C0 and noise terms alist."
  (%make-affine-form :c0 (coerce c0 'double-float) :terms terms))

(defun make-affine-variable (c0 radius)
  "Create an affine variable centered at C0 with dedicated noise symbol representing +/- RADIUS."
  (let ((noise-id (incf *noise-symbol-counter*)))
    (%make-affine-form :c0 (coerce c0 'double-float)
                       :terms (list (cons noise-id (coerce radius 'double-float))))))

(defun affine-add (a1 a2)
  "Affine addition: (c1 + c2) + sum((x1_i + x2_i) * epsilon_i)."
  (let ((c (+ (affine-c0 a1) (affine-c0 a2)))
        (merged (copy-alist (affine-terms a1))))
    (dolist (term (affine-terms a2))
      (let* ((sym (car term))
             (coeff (cdr term))
             (existing (assoc sym merged)))
        (if existing
            (incf (cdr existing) coeff)
            (push (cons sym coeff) merged))))
    (make-affine-form c (delete-if (lambda (p) (zerop (cdr p))) merged))))

(defun affine-sub (a1 a2)
  "Affine subtraction: cancels correlated noise symbols exactly."
  (let ((c (- (affine-c0 a1) (affine-c0 a2)))
        (merged (copy-alist (affine-terms a1))))
    (dolist (term (affine-terms a2))
      (let* ((sym (car term))
             (coeff (cdr term))
             (existing (assoc sym merged)))
        (if existing
            (decf (cdr existing) coeff)
            (push (cons sym (- coeff)) merged))))
    (make-affine-form c (delete-if (lambda (p) (zerop (cdr p))) merged))))

(defun affine-scale (a scalar)
  "Scale affine form A by real scalar."
  (let ((s (coerce scalar 'double-float)))
    (make-affine-form (* (affine-c0 a) s)
                      (mapcar (lambda (p) (cons (car p) (* (cdr p) s)))
                              (affine-terms a)))))

(defun affine-radius (a)
  "Calculate the maximum deviation radius R = sum(|x_i|)."
  (reduce #'+ (mapcar (lambda (p) (abs (cdr p))) (affine-terms a))
          :initial-value 0.0d0))

(defun affine-to-interval (a)
  "Convert affine form A to sound enclosing interval [c0 - R, c0 + R]."
  (let ((r (affine-radius a))
        (c (affine-c0 a)))
    (make-interval (- c r) (+ c r))))
