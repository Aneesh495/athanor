;;;; interpreter.lisp - Abstract Interpreter for S-Expressions and Numerical Programs

(in-package #:athanor)

(defun abstract-eval (expr env)
  "Recursively evaluate EXPR in abstract environment ENV mapping variable symbols to intervals.
   Returns an INTERVAL structure."
  (cond
    ((numberp expr)
     (make-interval expr expr))
    ((symbolp expr)
     (let ((iv (cdr (assoc expr env :test #'eq))))
       (or iv (make-interval +neg-inf+ +pos-inf+))))
    ((consp expr)
     (let* ((op (car expr))
            (args (cdr expr))
            (child-ivs (mapcar (lambda (a) (abstract-eval a env)) args)))
       (case op
         (+ (reduce #'interval-add child-ivs))
         (- (if (= (length child-ivs) 1)
                (interval-sub (make-interval 0 0) (first child-ivs))
                (reduce #'interval-sub child-ivs)))
         (* (reduce #'interval-mul child-ivs))
         (/ (multiple-value-bind (res div0-p)
                (interval-div (first child-ivs) (second child-ivs))
              (declare (ignore div0-p))
              res))
         (abs
          (let* ((iv (first child-ivs))
                 (l (interval-lo iv))
                 (h (interval-hi iv)))
            (cond
              ((>= l 0) iv)
              ((<= h 0) (make-interval (- h) (- l)))
              (t (make-interval 0.0d0 (max (abs l) (abs h)))))))
         (sqrt
          (let* ((iv (first child-ivs))
                 (l (max 0.0d0 (interval-lo iv)))
                 (h (max 0.0d0 (interval-hi iv))))
            (make-interval (sqrt l) (sqrt h))))
         (sin
          (make-interval -1.0d0 1.0d0))
         (cos
          (make-interval -1.0d0 1.0d0))
         (exp
          (let ((iv (first child-ivs)))
            (make-interval (exp (max -700.0d0 (interval-lo iv)))
                           (exp (min 700.0d0 (interval-hi iv))))))
         (otherwise
          ;; Unknown operator: soundly default to top
          (make-interval +neg-inf+ +pos-inf+)))))
    (t (make-interval +neg-inf+ +pos-inf+))))
