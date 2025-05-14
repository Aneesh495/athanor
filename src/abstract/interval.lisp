;;;; interval.lisp - Interval Arithmetic Abstract Domain and Bounds Pruning

(in-package #:athanor)

(defparameter +pos-inf+ 1.0d12
  "Representation of positive infinity in numerical interval arithmetic.")

(defparameter +neg-inf+ -1.0d12
  "Representation of negative infinity in numerical interval arithmetic.")

(defstruct (interval (:constructor %make-interval) (:conc-name interval-))
  "Closed real interval [LO, HI]."
  (lo +neg-inf+ :type real)
  (hi +pos-inf+ :type real))

(defun make-interval (lo hi)
  "Construct an interval [LO, HI] ensuring valid ordering."
  (let ((l (if (eq lo :neg-inf) +neg-inf+ (coerce lo 'double-float)))
        (h (if (eq hi :pos-inf) +pos-inf+ (coerce hi 'double-float))))
    (if (> l h)
        (%make-interval :lo +pos-inf+ :hi +neg-inf+) ;; Bottom
        (%make-interval :lo l :hi h))))

(defun interval-bottom-p (iv)
  "Return T if IV represents the empty bottom interval."
  (> (interval-lo iv) (interval-hi iv)))

(defun interval-top-p (iv)
  "Return T if IV represents the unbounded [-inf, +inf] interval."
  (and (<= (interval-lo iv) +neg-inf+)
       (>= (interval-hi iv) +pos-inf+)))

(defun interval-contains-p (iv val)
  "Return T if VAL is contained within interval IV."
  (and (>= val (interval-lo iv))
       (<= val (interval-hi iv))))

(defun interval-contains-zero-p (iv)
  "Return T if zero is contained within interval IV."
  (interval-contains-p iv 0.0d0))

(defun interval-add (i1 i2)
  "Sound interval addition: [l1 + l2, h1 + h2]."
  (if (or (interval-bottom-p i1) (interval-bottom-p i2))
      (make-interval +pos-inf+ +neg-inf+)
      (make-interval (+ (interval-lo i1) (interval-lo i2))
                     (+ (interval-hi i1) (interval-hi i2)))))

(defun interval-sub (i1 i2)
  "Sound interval subtraction: [l1 - h2, h1 - l2]."
  (if (or (interval-bottom-p i1) (interval-bottom-p i2))
      (make-interval +pos-inf+ +neg-inf+)
      (make-interval (- (interval-lo i1) (interval-hi i2))
                     (- (interval-hi i1) (interval-lo i2)))))

(defun interval-mul (i1 i2)
  "Sound interval multiplication over all four endpoint products."
  (if (or (interval-bottom-p i1) (interval-bottom-p i2))
      (make-interval +pos-inf+ +neg-inf+)
      (let* ((l1 (interval-lo i1)) (h1 (interval-hi i1))
             (l2 (interval-lo i2)) (h2 (interval-hi i2))
             (p1 (* l1 l2))
             (p2 (* l1 h2))
             (p3 (* h1 l2))
             (p4 (* h1 h2)))
        (make-interval (min p1 p2 p3 p4)
                       (max p1 p2 p3 p4)))))

(defun interval-div (i1 i2)
  "Sound interval division. Returns (values result-interval zero-division-p)."
  (if (or (interval-bottom-p i1) (interval-bottom-p i2))
      (values (make-interval +pos-inf+ +neg-inf+) nil)
      (if (interval-contains-zero-p i2)
          ;; Denominator straddles zero: potential division by zero
          (values (make-interval +neg-inf+ +pos-inf+) t)
          (let* ((l1 (interval-lo i1)) (h1 (interval-hi i1))
                 (l2 (interval-lo i2)) (h2 (interval-hi i2))
                 (q1 (/ l1 l2))
                 (q2 (/ l1 h2))
                 (q3 (/ h1 l2))
                 (q4 (/ h1 h2)))
            (values (make-interval (min q1 q2 q3 q4)
                                   (max q1 q2 q3 q4))
                    nil)))))

(defun interval-intersect (i1 i2)
  "Lattice meet: intersection of two intervals."
  (let ((l (max (interval-lo i1) (interval-lo i2)))
        (h (min (interval-hi i1) (interval-hi i2))))
    (make-interval l h)))

(defun interval-hull (i1 i2)
  "Lattice join: convex hull enclosing both intervals."
  (cond
    ((interval-bottom-p i1) i2)
    ((interval-bottom-p i2) i1)
    (t
     (make-interval (min (interval-lo i1) (interval-lo i2))
                    (max (interval-hi i1) (interval-hi i2))))))

(defun interval-widen (i1 i2)
  "Interval widening operator: pushes diverging bounds directly to infinity."
  (cond
    ((interval-bottom-p i1) i2)
    ((interval-bottom-p i2) i1)
    (t
     (let ((l (if (< (interval-lo i2) (interval-lo i1)) +neg-inf+ (interval-lo i1)))
           (h (if (> (interval-hi i2) (interval-hi i1)) +pos-inf+ (interval-hi i1))))
       (make-interval l h)))))

(defun interval-narrow (i1 i2)
  "Interval narrowing operator: recovers refined bounds after widening."
  (let ((l (if (= (interval-lo i1) +neg-inf+) (interval-lo i2) (interval-lo i1)))
        (h (if (= (interval-hi i1) +pos-inf+) (interval-hi i2) (interval-hi i1))))
    (make-interval l h)))
