;;;; saturation.lisp - Equality Saturation Iteration Loop and Convergence Controller

(in-package #:athanor)

(defstruct (saturation-report (:constructor make-saturation-report) (:conc-name saturation-report-))
  "Telemetry artifact recording the results of an equality saturation execution."
  (iterations 0 :type fixnum)
  (nodes 0 :type fixnum)
  (classes 0 :type fixnum)
  (converged-p nil :type boolean)
  (time-ms 0.0 :type single-float))

(defun saturate (eg rb &key (max-iterations *max-iterations*)
                            (node-limit *node-limit*)
                            (time-limit-seconds *time-limit-seconds*)
                            (verbose *verbose*))
  "Run equality saturation on EG using the equational rules in RB until fixed-point or limit.
   Returns a SATURATION-REPORT instance."
  (declare (type egraph eg)
           (type rulebase rb)
           (type fixnum max-iterations node-limit)
           (type single-float time-limit-seconds))
  (let ((start-time (get-internal-real-time))
        (converged nil)
        (iter-count 0))
    ;; Ensure initial state is properly rebuilt and canonical
    (egraph-rebuild eg)

    (loop for iter from 1 to max-iterations
          do (let ((elapsed (/ (- (get-internal-real-time) start-time)
                               (float internal-time-units-per-second 1.0))))
               ;; Timeout check
               (when (> elapsed time-limit-seconds)
                 (when verbose
                   (format t "[Athanor] Saturation stopped: timeout reached (~F s)~%" elapsed))
                 (return))

               ;; Node count limit check
               (when (> (egraph-node-count eg) node-limit)
                 (when verbose
                   (format t "[Athanor] Saturation stopped: node limit reached (~D nodes)~%"
                           (egraph-node-count eg)))
                 (return))

               (setf iter-count iter)
               (let ((prev-nodes (egraph-node-count eg))
                     (prev-classes (egraph-class-count eg)))
                 ;; Step 1: Match and apply all rules
                 (let ((merges (apply-rules-once rb eg)))
                   ;; Step 2: Restore congruence closure invariant
                   (egraph-rebuild eg)

                   (when verbose
                     (format t "[Iteration ~2D] Merges: ~4D | Nodes: ~5D | Classes: ~5D~%"
                             iter merges (egraph-node-count eg) (egraph-class-count eg)))

                   ;; Convergence check: no merges performed and node count invariant
                   (when (and (zerop merges)
                              (= prev-nodes (egraph-node-count eg))
                              (= prev-classes (egraph-class-count eg)))
                     (setf converged t)
                     (return))))))

    (let* ((end-time (get-internal-real-time))
           (elapsed-ms (* 1000.0 (/ (- end-time start-time)
                                    (float internal-time-units-per-second 1.0)))))
      (make-saturation-report :iterations iter-count
                              :nodes (egraph-node-count eg)
                              :classes (egraph-class-count eg)
                              :converged-p converged
                              :time-ms (coerce elapsed-ms 'single-float)))))
