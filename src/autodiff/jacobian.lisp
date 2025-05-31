;;;; jacobian.lisp - Symbolic Gradient Vectors, Jacobians, and Hessian Matrices

(in-package #:athanor)

(defun grad-symbolic (expr var-list)
  "Compute the exact symbolic gradient vector grad(EXPR) across all variables in VAR-LIST."
  (mapcar (lambda (v) (diff-symbolic expr v)) var-list))

(defun jacobian-symbolic (expr-list var-list)
  "Compute the symbolic Jacobian matrix J_ij = d(F_i)/d(X_j) for vector function EXPR-LIST."
  (mapcar (lambda (expr)
            (grad-symbolic expr var-list))
          expr-list))

(defun hessian-symbolic (expr var-list)
  "Compute the symmetric symbolic Hessian matrix H_ij = d^2(EXPR)/(d(X_i) d(X_j))."
  (let ((first-grads (grad-symbolic expr var-list)))
    (mapcar (lambda (g_i)
              (grad-symbolic g_i var-list))
            first-grads)))
