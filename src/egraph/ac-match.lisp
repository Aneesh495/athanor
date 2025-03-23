;;;; ac-match.lisp - Associative-Commutative Pattern Matching and Canonicalization

(in-package #:athanor)

(defparameter *ac-operators* '(+ * logand logior logxor min max gcd lcm)
  "Operators known to satisfy both associativity: f(a, f(b, c)) = f(f(a, b), c)
   and commutativity: f(a, b) = f(b, a).")

(defun ac-symbol-p (op)
  "Return T if OP is a registered associative-commutative operator."
  (member op *ac-operators* :test #'eq))

(defun term-comparator (t1 t2)
  "Stable total ordering on S-expression terms for canonical AC sorting."
  (cond
    ((equal t1 t2) nil)
    ((and (numberp t1) (numberp t2)) (< t1 t2))
    ((numberp t1) t)
    ((numberp t2) nil)
    ((and (symbolp t1) (symbolp t2)) (string< (symbol-name t1) (symbol-name t2)))
    ((symbolp t1) t)
    ((symbolp t2) nil)
    ((and (consp t1) (consp t2))
     (let ((cmp-op (term-comparator (car t1) (car t2))))
       (if (equal (car t1) (car t2))
           (let ((len1 (length (cdr t1)))
                 (len2 (length (cdr t2))))
             (if (= len1 len2)
                 (loop for a in (cdr t1)
                       for b in (cdr t2)
                       unless (equal a b)
                         return (term-comparator a b)
                       finally (return nil))
                 (< len1 len2)))
           cmp-op)))
    ((consp t1) nil)
    (t t)))

(defun flatten-ac-term (op args)
  "Flatten nested occurrences of the associative operator OP among ARGS."
  (let ((flattened nil))
    (labels ((rec (items)
               (dolist (item items)
                 (if (and (consp item) (eq (car item) op))
                     (rec (cdr item))
                     (push item flattened)))))
      (rec args)
      (nreverse flattened))))

(defun ac-normalize (expr)
  "Recursively normalize EXPR by flattening and canonically sorting all AC operator subtrees."
  (cond
    ((atom expr) expr)
    ((consp expr)
     (let* ((op (car expr))
            (raw-args (mapcar #'ac-normalize (cdr expr))))
       (if (ac-symbol-p op)
           (let* ((flat-args (flatten-ac-term op raw-args))
                  (sorted-args (sort (copy-list flat-args) #'term-comparator)))
             (cons op sorted-args))
           (cons op raw-args))))
    (t expr)))

(defun multiset-subsets (multiset k)
  "Generate all combinations of K elements from MULTISET."
  (if (zerop k)
      (list (list nil multiset))
      (if (null multiset)
          nil
          (let* ((head (car multiset))
                 (tail (cdr multiset))
                 ;; Include head in chosen subset
                 (with-head (mapcar (lambda (pair)
                                      (list (cons head (car pair)) (cadr pair)))
                                    (multiset-subsets tail (1- k))))
                 ;; Exclude head from chosen subset
                 (without-head (mapcar (lambda (pair)
                                         (list (car pair) (cons head (cadr pair))))
                                       (multiset-subsets tail k))))
            (append with-head without-head)))))
