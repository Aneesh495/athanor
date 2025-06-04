;;;; lisp-jit.lisp - Dynamic Native Machine Code Compilation via SBCL JIT

(in-package #:athanor)

(defun compile-expr-to-lisp (expr params &key (speed 3) (safety 0))
  "Compile S-expression EXPR into high-performance native machine code via the SBCL compiler.
   Returns a callable compiled function."
  (let* ((decl-types
           (mapcar (lambda (p)
                     `(type double-float ,p))
                   params))
         (fn-form
           `(lambda ,params
              (declare (optimize (speed ,speed) (safety ,safety))
                       ,@decl-types)
              (the double-float (float ,expr 1.0d0)))))
    (compile nil fn-form)))

(defun compile-integer-kernel (expr params &key (speed 3) (safety 0))
  "Compile integer or bitwise S-expression into native 64-bit machine code."
  (let* ((decl-types
           (mapcar (lambda (p)
                     `(type (signed-byte 64) ,p))
                   params))
         (fn-form
           `(lambda ,params
              (declare (optimize (speed ,speed) (safety ,safety))
                       ,@decl-types)
              (the (signed-byte 64) ,expr))))
    (compile nil fn-form)))
