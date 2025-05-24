;;;; dual.lisp - Forward-Mode Automatic Differentiation with Dual Numbers

(in-package #:athanor)

(defstruct (dual (:constructor %make-dual) (:conc-name dual-))
  "Dual number representing value and infinitesimal perturbation: f(x) + f'(x)*epsilon."
  (val 0.0d0 :type double-float)
  (dot 0.0d0 :type double-float))

(defun make-dual (val &optional (dot 0.0d0))
  "Allocate a dual number with primal value VAL and tangent direction DOT."
  (%make-dual :val (coerce val 'double-float)
              :dot (coerce dot 'double-float)))

(defun dual-add (d1 d2)
  "Dual number addition: (u + v) + (u' + v')*eps."
  (let ((v1 (if (dual-p d1) (dual-val d1) (coerce d1 'double-float)))
        (t1 (if (dual-p d1) (dual-dot d1) 0.0d0))
        (v2 (if (dual-p d2) (dual-val d2) (coerce d2 'double-float)))
        (t2 (if (dual-p d2) (dual-dot d2) 0.0d0)))
    (make-dual (+ v1 v2) (+ t1 t2))))

(defun dual-sub (d1 d2)
  "Dual number subtraction: (u - v) + (u' - v')*eps."
  (let ((v1 (if (dual-p d1) (dual-val d1) (coerce d1 'double-float)))
        (t1 (if (dual-p d1) (dual-dot d1) 0.0d0))
        (v2 (if (dual-p d2) (dual-val d2) (coerce d2 'double-float)))
        (t2 (if (dual-p d2) (dual-dot d2) 0.0d0)))
    (make-dual (- v1 v2) (- t1 t2))))

(defun dual-mul (d1 d2)
  "Dual number multiplication (product rule): (u*v) + (u*v' + u'*v)*eps."
  (let ((v1 (if (dual-p d1) (dual-val d1) (coerce d1 'double-float)))
        (t1 (if (dual-p d1) (dual-dot d1) 0.0d0))
        (v2 (if (dual-p d2) (dual-val d2) (coerce d2 'double-float)))
        (t2 (if (dual-p d2) (dual-dot d2) 0.0d0)))
    (make-dual (* v1 v2)
               (+ (* v1 t2) (* t1 v2)))))

(defun dual-div (d1 d2)
  "Dual number division (quotient rule): (u/v) + ((u'*v - u*v') / v^2)*eps."
  (let ((v1 (if (dual-p d1) (dual-val d1) (coerce d1 'double-float)))
        (t1 (if (dual-p d1) (dual-dot d1) 0.0d0))
        (v2 (if (dual-p d2) (dual-val d2) (coerce d2 'double-float)))
        (t2 (if (dual-p d2) (dual-dot d2) 0.0d0)))
    (when (zerop v2)
      (error 'athanor-error :message "Division by zero in dual number arithmetic"))
    (make-dual (/ v1 v2)
               (/ (- (* t1 v2) (* v1 t2)) (* v2 v2)))))

(defun dual-sin (d)
  "Dual sine: sin(u) + cos(u)*u'*eps."
  (let ((v (dual-val d))
        (t1 (dual-dot d)))
    (make-dual (sin v) (* (cos v) t1))))

(defun dual-cos (d)
  "Dual cosine: cos(u) - sin(u)*u'*eps."
  (let ((v (dual-val d))
        (t1 (dual-dot d)))
    (make-dual (cos v) (* (- (sin v)) t1))))

(defun dual-exp (d)
  "Dual exponential: exp(u) + exp(u)*u'*eps."
  (let ((v (dual-val d))
        (t1 (dual-dot d)))
    (let ((ev (exp v)))
      (make-dual ev (* ev t1)))))

(defun dual-log (d)
  "Dual logarithm: log(u) + (u'/u)*eps."
  (let ((v (dual-val d))
        (t1 (dual-dot d)))
    (when (<= v 0.0d0)
      (error 'athanor-error :message "Logarithm of non-positive dual value"))
    (make-dual (log v) (/ t1 v))))

(defun diff-forward (expr wrt-var env)
  "Compute the exact derivative d(EXPR)/d(WRT-VAR) evaluated at ENV using forward-mode dual numbers."
  (labels ((eval-dual (sub)
             (cond
               ((numberp sub) (make-dual sub 0.0d0))
               ((symbolp sub)
                (let ((val (cdr (assoc sub env :test #'eq))))
                  (unless val
                    (error 'athanor-error
                           :message (format nil "Unbound variable in dual evaluation: ~S" sub)))
                  (if (eq sub wrt-var)
                      (make-dual val 1.0d0)
                      (make-dual val 0.0d0))))
               ((consp sub)
                (let ((op (car sub))
                      (args (mapcar #'eval-dual (cdr sub))))
                  (case op
                    (+ (reduce #'dual-add args))
                    (- (if (= (length args) 1)
                           (dual-sub (make-dual 0 0) (first args))
                           (reduce #'dual-sub args)))
                    (* (reduce #'dual-mul args))
                    (/ (dual-div (first args) (second args)))
                    (sin (dual-sin (first args)))
                    (cos (dual-cos (first args)))
                    (exp (dual-exp (first args)))
                    (log (dual-log (first args)))
                    (otherwise
                     (error 'athanor-error :message (format nil "Unsupported dual operator: ~S" op))))))
               (t (error 'athanor-error :message (format nil "Invalid dual term: ~S" sub))))))
    (let ((res (eval-dual expr)))
      (values (dual-val res) (dual-dot res)))))
