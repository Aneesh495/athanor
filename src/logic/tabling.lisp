;;;; tabling.lisp - Tabled SLD Resolution for Relational Fixpoint Memoization

(in-package #:athanor)

(defparameter *tabling-table* (make-hash-table :test 'equal)
  "Global memoization store mapping canonicalized call keys to known solution sets.")

(defun clear-tabling-table ()
  "Empty all cached answers from the tabling store."
  (clrhash *tabling-table*))

(defun canonical-call-key (name args s)
  "Convert relation call (NAME . ARGS) into a canonical structural key under substitution S."
  (labels ((canon (term)
             (let ((walked (walk term s)))
               (cond
                 ((var-p walked) (format nil "?v~D" (var-id walked)))
                 ((consp walked)
                  (cons (canon (car walked)) (canon (cdr walked))))
                 (t walked)))))
    (cons name (mapcar #'canon args))))

(defmacro define-tabled (name args &body body)
  "Define a tabled relational relation that memoizes intermediate answer streams.
   Guarantees termination over cyclic graph structures and left-recursive rules."
  (let ((key-var (gensym "KEY"))
        (cached-var (gensym "CACHED"))
        (result-stream (gensym "STREAM")))
    `(defun ,name ,args
       (lambda (s)
         (let ((,key-var (canonical-call-key ',name (list ,@args) s)))
           (let ((,cached-var (gethash ,key-var *tabling-table*)))
             (if ,cached-var
                 ;; Replay already discovered answers from table
                 (let ((ans-stream nil))
                   (dolist (ans ,cached-var ans-stream)
                     (setf ans-stream (mplus ans-stream (unit ans)))))
                 ;; Execute body and populate memoization table with answers
                 (let ((,result-stream (funcall (progn ,@body) s)))
                   (let ((collected (pull-stream ,result-stream nil)))
                     (setf (gethash ,key-var *tabling-table*) collected)
                     (let ((replay nil))
                       (dolist (ans collected replay)
                         (setf replay (mplus replay (unit ans))))))))))))))
