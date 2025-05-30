;;;; tape.lisp - Reverse-Mode Execution Tape for Vectorized Computational Graphs

(in-package #:athanor)

(defstruct (tape-node (:constructor make-tape-node) (:conc-name tape-node-))
  "Single operation entry in a reverse-mode Wengert execution tape."
  (id 0 :type fixnum)
  (op nil :type symbol)
  (parents nil :type list)
  (primal 0.0d0 :type double-float)
  (adjoint 0.0d0 :type double-float))

(defstruct (ad-tape (:constructor make-ad-tape) (:conc-name ad-tape-))
  "Computational tape recording forward operations for subsequent reverse adjoint propagation."
  (nodes (make-array 64 :adjustable t :fill-pointer 0)
   :type vector))

(defun tape-push-node (tape op parents primal)
  "Record a newly computed node on the reverse tape."
  (let* ((nodes (ad-tape-nodes tape))
         (new-id (fill-pointer nodes))
         (tn (make-tape-node :id new-id :op op :parents parents :primal (coerce primal 'double-float))))
    (vector-push-extend tn nodes)
    new-id))

(defun tape-backward (tape output-id)
  "Propagate adjoint gradients in reverse topological order from OUTPUT-ID."
  (let ((nodes (ad-tape-nodes tape)))
    ;; Seed the output adjoint with 1.0 (d(out)/d(out))
    (setf (tape-node-adjoint (aref nodes output-id)) 1.0d0)

    ;; Sweep backward from output down to inputs
    (loop for i from output-id downto 0
          for tn = (aref nodes i)
          for adj of-type double-float = (tape-node-adjoint tn)
          when (/= adj 0.0d0)
          do (let ((op (tape-node-op tn))
                   (parents (tape-node-parents tn)))
               (case op
                 (+
                  (dolist (p parents)
                    (incf (tape-node-adjoint (aref nodes p)) adj)))
                 (-
                  (if (= (length parents) 1)
                      (decf (tape-node-adjoint (aref nodes (first parents))) adj)
                      (progn
                        (incf (tape-node-adjoint (aref nodes (first parents))) adj)
                        (decf (tape-node-adjoint (aref nodes (second parents))) adj))))
                 (*
                  (let* ((p1 (first parents))
                         (p2 (second parents))
                         (v1 (tape-node-primal (aref nodes p1)))
                         (v2 (tape-node-primal (aref nodes p2))))
                    (incf (tape-node-adjoint (aref nodes p1)) (* adj v2))
                    (incf (tape-node-adjoint (aref nodes p2)) (* adj v1))))
                 (sin
                  (let* ((p (first parents))
                         (v (tape-node-primal (aref nodes p))))
                    (incf (tape-node-adjoint (aref nodes p)) (* adj (cos v)))))
                 (cos
                  (let* ((p (first parents))
                         (v (tape-node-primal (aref nodes p))))
                    (incf (tape-node-adjoint (aref nodes p)) (* adj (- (sin v))))))
                 (exp
                  (let* ((p (first parents))
                         (v (tape-node-primal (aref nodes p))))
                    (incf (tape-node-adjoint (aref nodes p)) (* adj (exp v))))))))
    nodes))
