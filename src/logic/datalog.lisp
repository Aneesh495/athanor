;;;; datalog.lisp - Stratified Datalog Engine with Semi-Naive Fixpoint Evaluation

(in-package #:athanor)

(defstruct (datalog-engine (:constructor make-datalog-engine) (:conc-name datalog-))
  "Deductive database engine supporting stratified Datalog with semi-naive evaluation."
  (facts (make-hash-table :test 'eq) :type hash-table)
  (rules nil :type list))

(defun datalog-assert (engine rel tuple)
  "Assert a ground fact tuple into relation REL in ENGINE.
   Returns T if newly added, NIL if already existing."
  (declare (type datalog-engine engine)
           (type symbol rel)
           (type list tuple))
  (let ((current (gethash rel (datalog-facts engine))))
    (unless (member tuple current :test #'equal)
      (setf (gethash rel (datalog-facts engine)) (cons tuple current))
      t)))

(defun datalog-retract (engine rel tuple)
  "Remove ground fact TUPLE from relation REL in ENGINE."
  (declare (type datalog-engine engine)
           (type symbol rel)
           (type list tuple))
  (let ((current (gethash rel (datalog-facts engine))))
    (setf (gethash rel (datalog-facts engine))
          (delete tuple current :test #'equal))))

(defstruct (datalog-rule (:constructor make-datalog-rule-struct) (:conc-name dt-rule-))
  "A Datalog Horn clause rule: Head :- Body_1, Body_2, ..."
  (head nil :type list)
  (body nil :type list))

(defun datalog-rule (engine head body)
  "Register a deductive inference rule with HEAD literal and list of BODY literals."
  (declare (type datalog-engine engine)
           (type list head body))
  (push (make-datalog-rule-struct :head head :body body) (datalog-rules engine))
  engine)

(defun match-fact-pattern (pat tuple env)
  "Match a literal pattern PAT against a concrete ground fact TUPLE under ENV.
   Returns updated ENV alist, or NIL on mismatch."
  (if (/= (length pat) (length tuple))
      nil
      (let ((curr env)
            (matched t))
        (loop for p in pat
              for item in tuple
              while matched
              do (if (pattern-var-p p)
                     (let ((b (assoc p curr)))
                       (if b
                           (unless (equal (cdr b) item)
                             (setf matched nil))
                           (push (cons p item) curr)))
                     (unless (equal p item)
                       (setf matched nil))))
        (and matched curr))))

(defun evaluate-body-conjunction (body engine env)
  "Evaluate conjunction of body literals in ENGINE against current database under ENV.
   Returns list of successful binding environments."
  (if (null body)
      (list env)
      (let* ((literal (car body))
             (rest-literals (cdr body))
             (is-neg (eq (car literal) 'not))
             (actual-lit (if is-neg (second literal) literal))
             (rel (car actual-lit))
             (pat (cdr actual-lit))
             (known-facts (gethash rel (datalog-facts engine))))
        (if is-neg
            ;; Stratified Negation as Failure: succeeds if no ground facts match
            (let ((sub-matches nil))
              (dolist (fact known-facts)
                (let ((m (match-fact-pattern pat fact env)))
                  (when m (push m sub-matches))))
              (if (null sub-matches)
                  (evaluate-body-conjunction rest-literals engine env)
                  nil))
            ;; Positive Literal: join with matching facts
            (let ((extended-envs nil))
              (dolist (fact known-facts)
                (let ((m (match-fact-pattern pat fact env)))
                  (when m
                    (push m extended-envs))))
              (let ((results nil))
                (dolist (e extended-envs results)
                  (let ((sub-res (evaluate-body-conjunction rest-literals engine e)))
                    (dolist (sr sub-res)
                      (push sr results))))))))))

(defun instantiate-head (head env)
  "Instantiate rule HEAD literal using variable bindings in ENV."
  (let ((rel (car head))
        (args (cdr head)))
    (cons rel
          (mapcar (lambda (arg)
                    (if (pattern-var-p arg)
                        (let ((b (assoc arg env)))
                          (if b (cdr b)
                              (error 'athanor-error
                                     :message (format nil "Unbound variable in rule head: ~S" arg))))
                        arg))
                  args))))

(defun datalog-fixpoint (engine &optional (max-iterations 100))
  "Compute the minimal fixpoint deductive closure of ENGINE using semi-naive iteration.
   Returns total number of new facts derived."
  (let ((total-derived 0))
    (loop for iter from 1 to max-iterations
          do (let ((new-facts-this-round 0))
               (dolist (rule (datalog-rules engine))
                 (let ((matches (evaluate-body-conjunction (dt-rule-body rule) engine nil)))
                   (dolist (env matches)
                     (let* ((inst (instantiate-head (dt-rule-head rule) env))
                            (rel (car inst))
                            (tuple (cdr inst)))
                       (when (datalog-assert engine rel tuple)
                         (incf new-facts-this-round)
                         (incf total-derived))))))
               (when (zerop new-facts-this-round)
                 (return))))
    total-derived))

(defun datalog-query (engine query-literal)
  "Query ENGINE for all ground facts satisfying QUERY-LITERAL.
   Returns list of matching ground tuples or binding alists."
  (let* ((rel (car query-literal))
         (pat (cdr query-literal))
         (facts (gethash rel (datalog-facts engine)))
         (results nil))
    (dolist (fact facts (nreverse results))
      (let ((env (match-fact-pattern pat fact nil)))
        (when env
          (push (cons fact env) results))))))
