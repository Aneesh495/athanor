;;;; symbolic.lisp - Source-to-Source Reverse-Mode Symbolic Differentiation

(in-package #:athanor)

(defun diff-symbolic (expr wrt-var)
  "Generate the exact analytical symbolic derivative S-expression d(EXPR)/d(WRT-VAR)."
  (cond
    ;; Constant numbers differentiate to 0
    ((numberp expr) 0)

    ;; Variables: 1 if target variable, 0 otherwise
    ((symbolp expr)
     (if (eq expr wrt-var) 1 0))

    ;; Compound mathematical expressions
    ((consp expr)
     (let ((op (car expr))
           (args (cdr expr)))
       (case op
         (+
          (cons '+ (mapcar (lambda (a) (diff-symbolic a wrt-var)) args)))

         (-
          (if (= (length args) 1)
              (list '- (diff-symbolic (first args) wrt-var))
              (list '- (diff-symbolic (first args) wrt-var)
                       (diff-symbolic (second args) wrt-var))))

         (*
          (if (= (length args) 2)
              (let ((u (first args))
                    (v (second args)))
                (list '+ (list '* (diff-symbolic u wrt-var) v)
                         (list '* u (diff-symbolic v wrt-var))))
              (diff-symbolic (list '* (first args) (cons '* (cdr args))) wrt-var)))

         (/
          (let ((u (first args))
                (v (second args)))
            (list '/
                  (list '-
                        (list '* (diff-symbolic u wrt-var) v)
                        (list '* u (diff-symbolic v wrt-var)))
                  (list 'expt v 2))))

         (sin
          (let ((u (first args)))
            (list '* (list 'cos u) (diff-symbolic u wrt-var))))

         (cos
          (let ((u (first args)))
            (list '* (list '- (list 'sin u)) (diff-symbolic u wrt-var))))

         (tan
          (let ((u (first args)))
            (list '* (list '+ 1 (list 'expt (list 'tan u) 2))
                  (diff-symbolic u wrt-var))))

         (exp
          (let ((u (first args)))
            (list '* (list 'exp u) (diff-symbolic u wrt-var))))

         (log
          (let ((u (first args)))
            (list '/ (diff-symbolic u wrt-var) u)))

         (sqrt
          (let ((u (first args)))
            (list '/ (diff-symbolic u wrt-var)
                  (list '* 2 (list 'sqrt u)))))

         (expt
          (let ((u (first args))
                (n (second args)))
            (if (numberp n)
                (list '* n
                      (list '* (list 'expt u (- n 1))
                            (diff-symbolic u wrt-var)))
                ;; General power rule: d/dx(u^v) = u^v * (v'*ln(u) + v*u'/u)
                (list '* (list 'expt u n)
                      (list '+ (list '* (diff-symbolic n wrt-var) (list 'log u))
                            (list '/ (list '* n (diff-symbolic u wrt-var)) u))))))

         (otherwise
          (error 'athanor-error :message (format nil "Unsupported symbolic differentiator operator: ~S" op))))))

    (t (error 'athanor-error :message (format nil "Invalid term for symbolic differentiation: ~S" expr)))))
