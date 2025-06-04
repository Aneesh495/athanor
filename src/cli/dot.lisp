;;;; dot.lisp - Graphviz DOT Graph Exporter for E-Graph Visualization

(in-package #:athanor)

(defun sanitize-dot-label (label)
  "Escape special characters for Graphviz DOT label strings."
  (let ((str (format nil "~A" label)))
    (let ((res nil))
      (loop for ch across str
            do (case ch
                 (#\" (push #\\ res) (push #\" res))
                 (#\\ (push #\\ res) (push #\\ res))
                 (#\Newline (push #\\ res) (push #\n res))
                 (otherwise (push ch res))))
      (coerce (nreverse res) 'string))))

(defun egraph-to-dot (eg &key (stream t) (highlight-class nil))
  "Export the current state of EG as a Graphviz DOT digraph to STREAM.
   Clusters e-nodes into distinct visual bounding boxes for each canonical e-class."
  (format stream "digraph EGraph {~%")
  (format stream "    compound=true;~%")
  (format stream "    clusterrank=local;~%")
  (format stream "    node [fontname=\"Helvetica\", fontsize=10];~%")
  (format stream "    edge [fontname=\"Helvetica\", fontsize=9];~%~%")

  (let ((node-id-counter 0)
        (node-ids (make-hash-table :test 'enode-equal-p)))
    ;; Phase 1: Emit all e-classes as cluster subgraphs
    (maphash (lambda (root-id ec)
               (let ((is-highlight (and highlight-class (= root-id highlight-class))))
                 (format stream "    subgraph cluster_~D {~%" root-id)
                 (format stream "        label = \"Class ~D\";~%" root-id)
                 (format stream "        style = filled;~%")
                 (format stream "        color = ~A;~%"
                         (if is-highlight "\"#ffebee\"" "\"#f5f5f5\""))
                 (format stream "        fillcolor = ~A;~%"
                         (if is-highlight "\"#fff8e1\"" "\"#fafafa\""))

                 (dolist (node (eclass-nodes ec))
                   (let ((nid (incf node-id-counter)))
                     (setf (gethash node node-ids) nid)
                     (let ((op-label (sanitize-dot-label (enode-op node))))
                       (format stream "        node_~D [label=\"~A\", shape=box, style=rounded, fillcolor=white];~%"
                               nid op-label))))
                 (format stream "    }~%~%")))
             (egraph-classes eg))

    ;; Phase 2: Emit directed edges connecting e-nodes to their child e-classes
    (maphash (lambda (root-id ec)
               (declare (ignore root-id))
               (dolist (node (eclass-nodes ec))
                 (let ((src-id (gethash node node-ids))
                       (children (enode-children node)))
                   (loop for i from 0 below (length children)
                         for child-class-id of-type e-id = (egraph-find eg (aref children i))
                         for child-ec = (get-eclass eg child-class-id)
                         when (and child-ec (eclass-nodes child-ec))
                         do (let* ((first-child-node (first (eclass-nodes child-ec)))
                                   (tgt-id (gethash first-child-node node-ids)))
                              (format stream "    node_~D -> node_~D [lhead=cluster_~D, label=\"arg ~D\"];~%"
                                      src-id tgt-id child-class-id i))))))
             (egraph-classes eg)))

  (format stream "}~%")
  nil)
