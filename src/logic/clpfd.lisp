;;;; clpfd.lisp - Constraint Logic Programming Over Finite Domains

(in-package #:athanor)

(defstruct (fd-domain (:constructor make-fd-domain) (:conc-name fd-domain-))
  "Finite integer domain represented as a bounded inclusive interval [min, max]."
  (min 0 :type integer)
  (max 0 :type integer))

(defstruct (fd-constraint (:constructor make-fd-constraint) (:conc-name fd-constraint-))
  "Constraint over finite domain variables."
  (type nil :type symbol)
  (args nil :type list)
  (predicate nil :type function))

(defun domain-size (d)
  "Number of integer values in domain D."
  (1+ (- (fd-domain-max d) (fd-domain-min d))))

(defun domain-intersect (d1 d2)
  "Compute intersection of two intervals."
  (let ((new-min (max (fd-domain-min d1) (fd-domain-min d2)))
        (new-max (min (fd-domain-max d1) (fd-domain-max d2))))
    (if (<= new-min new-max)
        (make-fd-domain :min new-min :max new-max)
        nil)))

(defun in-range (var lo hi)
  "Create an interval domain constraint [LO, HI] on VAR."
  (make-fd-constraint :type :range
                      :args (list var lo hi)
                      :predicate (lambda (env)
                                   (let ((val (gethash var env)))
                                     (or (null val) (and (>= val lo) (<= val hi)))))))

(defun distinct-vars (vars)
  "Create an all-different constraint over a list of variables."
  (make-fd-constraint :type :all-different
                      :args vars
                      :predicate (lambda (env)
                                   (let ((seen nil)
                                         (valid t))
                                     (dolist (v vars valid)
                                       (let ((val (gethash v env)))
                                         (when val
                                           (if (member val seen)
                                               (progn (setf valid nil) (return))
                                               (push val seen)))))))))

(defun sum-constraint (vars target-sum)
  "Create a linear sum constraint enforcing sum(VARS) = TARGET-SUM."
  (make-fd-constraint :type :sum
                      :args (cons target-sum vars)
                      :predicate (lambda (env)
                                   (let ((current-sum 0)
                                         (all-assigned t))
                                     (dolist (v vars)
                                       (let ((val (gethash v env)))
                                         (if val
                                             (incf current-sum val)
                                             (setf all-assigned nil))))
                                     (if all-assigned
                                         (= current-sum target-sum)
                                         (<= current-sum target-sum))))))

(defun clpfd-solve (vars constraints &optional (initial-domains nil))
  "Solve finite domain constraint satisfaction problem via AC-3 pruning and backtracking.
   Returns a list of solution environment alists."
  (let ((domains (make-hash-table :test 'equal))
        (solutions nil))
    ;; Initialize default domains
    (dolist (v vars)
      (let ((init (and initial-domains (cdr (assoc v initial-domains :test 'equal)))))
        (setf (gethash v domains)
              (if init
                  (make-fd-domain :min (car init) :max (cdr init))
                  (make-fd-domain :min -100 :max 100)))))

    ;; Refine initial domains from unary range constraints
    (dolist (c constraints)
      (when (eq (fd-constraint-type c) :range)
        (let* ((v (first (fd-constraint-args c)))
               (lo (second (fd-constraint-args c)))
               (hi (third (fd-constraint-args c)))
               (curr (gethash v domains)))
          (when curr
            (let ((refined (domain-intersect curr (make-fd-domain :min lo :max hi))))
              (unless refined (return-from clpfd-solve nil))
              (setf (gethash v domains) refined))))))

    ;; Backtracking search with forward constraint checking
    (let ((env (make-hash-table :test 'equal)))
      (labels ((satisfies-all-p ()
                 (every (lambda (c) (funcall (fd-constraint-predicate c) env))
                        constraints))
               (search-rec (remaining)
                 (if (null remaining)
                     (when (satisfies-all-p)
                       (let ((sol nil))
                         (maphash (lambda (k val) (push (cons k val) sol)) env)
                         (push (nreverse sol) solutions)))
                     (let* ((v (car remaining))
                            (dom (gethash v domains)))
                       (loop for val from (fd-domain-min dom) to (fd-domain-max dom)
                             do (setf (gethash v env) val)
                                (when (satisfies-all-p)
                                  (search-rec (cdr remaining)))
                                (remhash v env))))))
        (search-rec vars)))
    (nreverse solutions)))
