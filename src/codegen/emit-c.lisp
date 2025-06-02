;;;; emit-c.lisp - C99/C11 Code Emitter with Vectorization Pragmas

(in-package #:athanor)

(defun sanitize-c-ident (sym)
  "Convert Lisp symbol to valid C identifier string."
  (let ((str (string-downcase (symbol-name sym))))
    (substitute #\_ #\- str)))

(defun emit-c-expression (expr)
  "Translate S-expression EXPR into a formatted C infix expression string."
  (cond
    ((numberp expr)
     (if (floatp expr)
         (format nil "~F" expr)
         (format nil "~D" expr)))
    ((symbolp expr)
     (sanitize-c-ident expr))
    ((consp expr)
     (let ((op (car expr))
           (args (cdr expr)))
       (case op
         (+
          (format nil "(~{~A~^ + ~})" (mapcar #'emit-c-expression args)))
         (-
          (if (= (length args) 1)
              (format nil "(-~A)" (emit-c-expression (first args)))
              (format nil "(~A - ~A)"
                      (emit-c-expression (first args))
                      (emit-c-expression (second args)))))
         (*
          (format nil "(~{~A~^ * ~})" (mapcar #'emit-c-expression args)))
         (/
          (format nil "(~A / ~A)"
                  (emit-c-expression (first args))
                  (emit-c-expression (second args))))
         (ash
          (let ((shift (second args)))
            (if (and (numberp shift) (< shift 0))
                (format nil "(~A >> ~D)" (emit-c-expression (first args)) (- shift))
                (format nil "(~A << ~A)" (emit-c-expression (first args)) (emit-c-expression shift)))))
         (logand
          (format nil "(~{~A~^ & ~})" (mapcar #'emit-c-expression args)))
         (logior
          (format nil "(~{~A~^ | ~})" (mapcar #'emit-c-expression args)))
         (logxor
          (format nil "(~{~A~^ ^ ~})" (mapcar #'emit-c-expression args)))
         (lognot
          (format nil "(~~~A)" (emit-c-expression (first args))))
         (sin
          (format nil "sin(~A)" (emit-c-expression (first args))))
         (cos
          (format nil "cos(~A)" (emit-c-expression (first args))))
         (tan
          (format nil "tan(~A)" (emit-c-expression (first args))))
         (exp
          (format nil "exp(~A)" (emit-c-expression (first args))))
         (log
          (format nil "log(~A)" (emit-c-expression (first args))))
         (sqrt
          (format nil "sqrt(~A)" (emit-c-expression (first args))))
         (expt
          (let ((u (first args))
                (n (second args)))
            (if (and (numberp n) (= n 2))
                (let ((sub (emit-c-expression u)))
                  (format nil "(~A * ~A)" sub sub))
                (format nil "pow(~A, ~A)"
                        (emit-c-expression u)
                        (emit-c-expression n)))))
         (otherwise
          (format nil "~A(~{~A~^, ~})" (sanitize-c-ident op) (mapcar #'emit-c-expression args))))))
    (t (format nil "/* invalid */ 0"))))

(defun emit-c-function (name expr param-types &optional (return-type 'double))
  "Generate complete standalone C function definition implementing EXPR."
  (let* ((c-name (if (symbolp name) (sanitize-c-ident name) (string name)))
         (ret-str (c-type-specifier return-type))
         (param-strs
           (mapcar (lambda (p)
                     (format nil "~A ~A"
                             (c-type-specifier (cdr p))
                             (sanitize-c-ident (car p))))
                   param-types))
         (body-expr (emit-c-expression expr)))
    (format nil "~A ~A(~{~A~^, ~}) {~%    return ~A;~%}~%"
            ret-str c-name param-strs body-expr)))

(defun emit-c-vector-kernel (name expr in-params &optional (elem-type "double"))
  "Generate an OpenMP SIMD vectorized batch evaluation kernel over continuous arrays."
  (let* ((c-name (if (symbolp name) (sanitize-c-ident name) (string name)))
         (param-decl
           (mapcar (lambda (p)
                     (format nil "const ~A* restrict ~A"
                             elem-type (sanitize-c-ident p)))
                   in-params))
         ;; Substitute input variables to array indices x[i]
         (indexed-expr
           (labels ((subst-idx (sub)
                      (cond
                        ((and (symbolp sub) (member sub in-params :test #'eq))
                         (intern (format nil "~A[i]" (sanitize-c-ident sub))))
                        ((consp sub)
                         (cons (car sub) (mapcar #'subst-idx (cdr sub))))
                        (t sub))))
             (subst-idx expr))))
    (format nil "void ~A_batch(size_t n, ~{~A, ~}~A* restrict out) {~%    #pragma omp simd~%    for (size_t i = 0; i < n; ++i) {~%        out[i] = ~A;~%    }~%}~%"
            c-name param-decl elem-type (emit-c-expression indexed-expr))))
