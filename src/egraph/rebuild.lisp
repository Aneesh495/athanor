;;;; rebuild.lisp - Congruence Invariant Maintenance and Upward Rebuilding

(in-package #:athanor)

(defun rebuild-step (eg class-id)
  "Execute a single upward rebuild pass for the equivalence class CLASS-ID."
  (declare (type egraph eg)
           (type e-id class-id)
           (optimize (speed 3) (safety 1)))
  (let* ((uf (egraph-union-find eg))
         (hc (egraph-hash-cons eg))
         (root (uf-find uf class-id))
         (ec (gethash root (egraph-classes eg))))
    (when ec
      ;; Step 1: Canonicalize all e-nodes within this class
      (let ((canon-nodes nil))
        (dolist (node (eclass-nodes ec))
          (let ((canon (canonicalize-enode node uf)))
            (unless (member canon canon-nodes :test #'enode-equal-p)
              (push canon canon-nodes))))
        (setf (eclass-nodes ec) canon-nodes))

      ;; Step 2: Process upward parent pointers to propagate congruences
      (let ((parents (eclass-parents ec))
            (new-parents nil))
        (setf (eclass-parents ec) nil)
        (dolist (entry parents)
          (let* ((parent-node (car entry))
                 (parent-class-id (cdr entry))
                 (canon-pnode (canonicalize-enode parent-node uf))
                 (canon-pclass (uf-find uf parent-class-id)))
            ;; Check if this canonical parent node is already in hash-cons
            (let ((existing-id (hc-lookup hc canon-pnode)))
              (if (and existing-id (/= (uf-find uf existing-id) canon-pclass))
                  ;; Discovered congruence: merge the two parent classes
                  (let ((merged-root (egraph-merge eg existing-id canon-pclass)))
                    (hc-insert hc canon-pnode merged-root))
                  ;; Otherwise record canonical parent in hash-cons
                  (progn
                    (hc-insert hc canon-pnode canon-pclass)
                    (push (cons canon-pnode canon-pclass) new-parents))))))
        ;; Re-attach deduplicated parent entries
        (dolist (entry new-parents)
          (add-parent-to-eclass ec (car entry) (cdr entry)))

        ;; Step 3: Trigger analysis modification if applicable
        (when (egraph-analysis eg)
          (let ((modified-data (analysis-modify (egraph-analysis eg) ec eg)))
            (setf (eclass-data ec) modified-data)))))))

(defun egraph-rebuild (eg)
  "Restore the invariant that the e-graph is a true congruence closure.
   Drains the worklist until a steady-state fixed point is achieved."
  (declare (type egraph eg))
  (loop while (egraph-worklist eg)
        do (let ((todo (egraph-worklist eg)))
             (setf (egraph-worklist eg) nil)
             (dolist (class-id todo)
               (rebuild-step eg class-id))))
  (setf (egraph-clean-p eg) t)
  t)
