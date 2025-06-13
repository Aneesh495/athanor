;;;; matcher.lisp - Backtracking E-Graph Pattern Matcher and Substitution

(in-package #:athanor)

(defstruct (match (:constructor make-match))
  "A successful pattern match against an e-class with variable bindings."
  (subst nil :type list)
  (class-id 0 :type e-id))

(defun match-pattern-in-class (pat class-id eg subst)
  "Attempt to match PAT against the equivalence class CLASS-ID in EG under SUBST.
   Returns a list of valid extended substitution alists."
  (declare (type t pat)
           (type e-id class-id)
           (type egraph eg)
           (type list subst)
           (optimize (speed 3) (safety 1)))
  (let ((root (egraph-find eg class-id)))
    (cond
      ;; Pattern is a variable (?x)
      ((pattern-var-p pat)
       (let ((binding (assoc pat subst)))
         (if binding
             ;; Variable already bound: check equivalence in e-graph
             (if (in-same-class-p eg (cdr binding) root)
                 (list subst)
                 nil)
             ;; Variable unbound: bind to current e-class root
             (list (acons pat root subst)))))

      ;; Pattern is a leaf atom / literal
      ((atom pat)
       (let ((ec (get-eclass eg root)))
         (when ec
           (if (some (lambda (node)
                       (and (zerop (length (enode-children node)))
                            (op-equal-p (enode-op node) pat)))
                     (eclass-nodes ec))
               (list subst)
               nil))))

      ;; Pattern is a compound term (op . arg-patterns)
      ((consp pat)
       (let* ((op (car pat))
              (arg-pats (cdr pat))
              (num-args (length arg-pats))
              (ec (get-eclass eg root))
              (results nil))
         (when ec
           (dolist (node (eclass-nodes ec))
             (when (and (op-equal-p (enode-op node) op)
                        (= (length (enode-children node)) num-args))
               ;; Match argument patterns against child e-class IDs sequentially
               (let ((current-substs (list subst)))
                 (loop for i from 0 below num-args
                       for arg-pat in arg-pats
                       for child-id of-type e-id = (aref (enode-children node) i)
                       while current-substs
                       do (let ((next-substs nil))
                            (dolist (s current-substs)
                              (let ((sub-matches (match-pattern-in-class arg-pat child-id eg s)))
                                (dolist (sm sub-matches)
                                  (push sm next-substs))))
                            (setf current-substs next-substs)))
                 (dolist (s current-substs)
                   (push s results))))))
         results))
      (t nil))))

(defun match-all-classes (pat eg)
  "Scan all active e-classes in EG for matches against PAT.
   Returns a list of MATCH structures."
  (declare (type t pat)
           (type egraph eg))
  (let* ((pat-ast (if (pattern-p pat) (pattern-ast pat) pat))
         (matches nil))
    (maphash (lambda (root-id ec)
               (declare (ignore ec))
               (let ((substs (match-pattern-in-class pat-ast root-id eg nil)))
                 (dolist (s substs)
                   (push (make-match :subst s :class-id root-id) matches))))
             (egraph-classes eg))
    matches))

(defun apply-substitution (rhs-ast subst eg)
  "Instantiate RHS-AST in EG replacing pattern variables with bound e-classes from SUBST.
   Returns the resulting canonical e-class ID."
  (declare (type t rhs-ast)
           (type list subst)
           (type egraph eg))
  (cond
    ((pattern-var-p rhs-ast)
     (let ((binding (assoc rhs-ast subst)))
       (unless binding
         (error 'athanor-error
                :message (format nil "Unbound pattern variable ~S in RHS expression ~S" rhs-ast rhs-ast)))
       (egraph-find eg (cdr binding))))
    ((atom rhs-ast)
     (egraph-add eg (make-enode rhs-ast #())))
    ((consp rhs-ast)
     (let* ((op (car rhs-ast))
            (args (cdr rhs-ast))
            (child-ids (make-array (length args) :element-type 'e-id)))
       (loop for i from 0
             for arg in args
             do (setf (aref child-ids i) (apply-substitution arg subst eg)))
       (egraph-add eg (make-enode op child-ids))))
    (t
     (error 'athanor-error :message (format nil "Invalid RHS term in substitution: ~S" rhs-ast)))))
