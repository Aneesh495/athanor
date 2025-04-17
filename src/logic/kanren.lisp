;;;; kanren.lisp - Pure Relational Logic Programming Kernel (miniKanren)

(in-package #:athanor)

;;; Logic Variables

(defparameter *var-counter* 0
  "Monotonically increasing counter for assigning unique logic variable IDs.")

(defstruct (var (:constructor %make-var) (:conc-name var-))
  "A logic variable identified by an integer index."
  (id 0 :type fixnum)
  (name nil :type symbol))

(defun make-var (&optional (name nil))
  "Allocate a fresh logic variable with optional debugging name."
  (%make-var :id (incf *var-counter*) :name name))

(defmethod print-object ((v var) stream)
  (if (var-name v)
      (format stream "_~A" (var-name v))
      (format stream "_~D" (var-id v))))

;;; Variable Walking and Substitution

(defun walk (u s)
  "Follow variable substitution chain for U in substitution alist S."
  (if (var-p u)
      (let ((binding (assoc u s :test #'eq)))
        (if binding
            (walk (cdr binding) s)
            u))
      u))

(defun extend-subst (x v s)
  "Extend substitution S with association (X . V)."
  (acons x v s))

(defun occurs-p (x v s)
  "Occurs check: return T if logic variable X appears inside term V."
  (let ((v (walk v s)))
    (cond
      ((var-p v) (eq x v))
      ((consp v)
       (or (occurs-p x (car v) s)
           (occurs-p x (cdr v) s)))
      (t nil))))

(defun unify (u v s)
  "Unify terms U and V under substitution S. Returns updated substitution, or NIL on failure."
  (let ((u (walk u s))
        (v (walk v s)))
    (cond
      ((eq u v) s)
      ((var-p u)
       (if (occurs-p u v s)
           nil
           (extend-subst u v s)))
      ((var-p v)
       (if (occurs-p v u s)
           nil
           (extend-subst v u s)))
      ((and (consp u) (consp v))
       (let ((s (unify (car u) (car v) s)))
         (and s (unify (cdr u) (cdr v) s))))
      ((equal u v) s)
      (t nil))))

;;; Stream Combinators for Interleaving Search

(defun mzero ()
  "Empty stream of solutions."
  nil)

(defun unit (s)
  "Single-element stream of substitution S."
  (list s))

(defun mplus (stream1 stream2)
  "Interleaving fair union of two streams."
  (cond
    ((null stream1) stream2)
    ((functionp stream1)
     (lambda () (mplus stream2 (funcall stream1))))
    (t
     (cons (car stream1) (mplus (cdr stream1) stream2)))))

(defun bind (stream goal)
  "Monadic bind: apply GOAL to every substitution in STREAM."
  (cond
    ((null stream) (mzero))
    ((functionp stream)
     (lambda () (bind (funcall stream) goal)))
    (t
     (mplus (funcall goal (car stream))
            (bind (cdr stream) goal)))))

;;; Core Relational Goal Constructors

(defun == (u v)
  "Relational equality goal: unifies U and V."
  (lambda (s)
    (let ((s1 (unify u v s)))
      (if s1 (unit s1) (mzero)))))

(defmacro fresh (vars &body goals)
  "Introduce fresh logic variables VARS lexically scoped within GOALS."
  (if (null vars)
      (if (null goals)
          '(lambda (s) (unit s))
          (if (null (cdr goals))
              (car goals)
              `(lambda (s)
                 (bind (funcall ,(car goals) s)
                       (fresh () ,@(cdr goals))))))
      `(let ,(mapcar (lambda (v) `(,v (make-var ',v))) vars)
         (fresh () ,@goals))))

(defmacro conde (&rest clauses)
  "Non-deterministic relational disjunction with interleaving stream search."
  (if (null clauses)
      '(lambda (s) (declare (ignore s)) (mzero))
      (labels ((expand-clause (goals)
                 (if (null goals)
                     '(lambda (s) (unit s))
                     (if (null (cdr goals))
                         (car goals)
                         `(lambda (s)
                            (bind (funcall ,(car goals) s)
                                  ,(expand-clause (cdr goals))))))))
        (let ((first-clause (expand-clause (car clauses)))
              (rest-clauses (cdr clauses)))
          (if (null rest-clauses)
              first-clause
              `(lambda (s)
                 (mplus (funcall ,first-clause s)
                        (funcall (conde ,@rest-clauses) s))))))))

;;; Reification and Query Execution

(defun walk* (v s)
  "Deeply walk term V replacing all bound logic variables with their values."
  (let ((v (walk v s)))
    (cond
      ((var-p v) v)
      ((consp v)
       (cons (walk* (car v) s)
             (walk* (cdr v) s)))
      (t v))))

(defun reify-name (n)
  "Generate readable reified symbol for the N-th unbound logic variable: _0, _1, etc."
  (intern (format nil "_~D" n)))

(defun reify-s (v r)
  "Construct substitution mapping each distinct unbound variable in V to a reified symbol."
  (let ((v (walk v r)))
    (cond
      ((var-p v)
       (let ((n (length r)))
         (acons v (reify-name n) r)))
      ((consp v)
       (let ((r (reify-s (car v) r)))
         (reify-s (cdr v) r)))
      (t r))))

(defun reify-term (v s)
  "Return completely reified, human-readable S-expression for V under S."
  (let ((v (walk* v s)))
    (let ((r (reify-s v nil)))
      (walk* v r))))

(defun pull-stream (stream n)
  "Extract up to N results from STREAM."
  (if (and n (<= n 0))
      nil
      (cond
        ((null stream) nil)
        ((functionp stream)
         (pull-stream (funcall stream) n))
        (t
         (cons (car stream)
               (pull-stream (cdr stream) (and n (1- n))))))))

(defmacro run (n (q) &body goals)
  "Execute GOALS, extracting up to N solutions reified for query variable Q."
  `(let ((,q (make-var ',q)))
     (let ((stream (funcall (fresh () ,@goals) nil)))
       (let ((substs (pull-stream stream ,n)))
         (mapcar (lambda (s) (reify-term ,q s)) substs)))))

(defmacro run* ((q) &body goals)
  "Execute GOALS and collect all solutions to query variable Q."
  `(run nil (,q) ,@goals))
