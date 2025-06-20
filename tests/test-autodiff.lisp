;;;; test-autodiff.lisp - Dual Numbers, Symbolic Differentiation, and Fused Gradients

(in-package #:athanor-test)

(deftest test-dual-numbers-forward-ad
  ;; Forward AD of f(x) = x^2 + 3x at x = 4.
  ;; f(4) = 16 + 12 = 28. f'(4) = 2x + 3 = 11.
  (let* ((x (make-dual 4.0d0 1.0d0))
         (x-sq (dual-mul x x))
         (three-x (dual-mul (make-dual 3.0d0 0.0d0) x))
         (res (dual-add x-sq three-x)))
    (assert-equal (dual-val res) 28.0d0)
    (assert-equal (dual-dot res) 11.0d0)))

(deftest test-symbolic-differentiation-rules
  ;; d/dx (x^2) = (* 2 (* (expt x 1) 1))
  (let ((g (diff-symbolic '(expt x 2) 'x)))
    (assert-true (consp g))
    (assert-equal (first g) '*))
  ;; d/dx (sin x) = (* (cos x) 1)
  (let ((g-sin (diff-symbolic '(sin x) 'x)))
    (assert-equal g-sin '(* (cos x) 1)))
  ;; d/dx (constant) = 0
  (let ((g-const (diff-symbolic 42 'x)))
    (assert-equal g-const 0)))

(deftest test-symbolic-gradient-and-hessian
  ;; f(x, y) = x^2 + y^2
  (let* ((expr '(+ (expt x 2) (expt y 2)))
         (grad (grad-symbolic expr '(x y))))
    (assert-equal (length grad) 2)
    ;; Hessian matrix is 2x2
    (let ((hess (hessian-symbolic expr '(x y))))
      (assert-equal (length hess) 2)
      (assert-equal (length (first hess)) 2)
      (assert-equal (length (second hess)) 2))))

(deftest test-fused-gradient-superoptimization
  ;; Differentiate x^2 with respect to x, then superoptimize with latency model:
  ;; Raw gradient: (* 2 (* (expt x 1) 1)) -> simplified to (ash x 1)
  (multiple-value-bind (opt raw rep)
      (differentiate-and-saturate '(expt x 2) 'x :cost-model :latency)
    (declare (ignore rep))
    (assert-true (consp raw))
    (assert-equal opt '(ash x 1))))
