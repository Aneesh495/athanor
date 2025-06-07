;;;; repl.lisp - Interactive Athanor Synthesis and Superoptimization Shell

(in-package #:athanor)

(defun print-repl-banner (&optional (stream t))
  "Display the ASCII banner and version header."
  (format stream "~%========================================================================~%")
  (format stream "   ATHANOR : Equality Saturation & Program Synthesis Kernel v~A~%" *athanor-version*)
  (format stream "========================================================================~%")
  (format stream "Type :help for a summary of available meta-commands.~%~%"))

(defun print-repl-help (&optional (stream t))
  "Print help guide for interactive REPL commands."
  (format stream "Athanor Interactive Shell Commands:~%")
  (format stream "  :sat <expr>                 Run equality saturation under standard equational theory~%")
  (format stream "  :diff <expr> <var>          Compute superoptimized analytical gradient~%")
  (format stream "  :synth <(inputs . out)...>  Inductively synthesize verified S-expression~%")
  (format stream "  :verify <expr> <var-ranges> Prove absence of division by zero & compute bounds~%")
  (format stream "  :emit-c <expr>              Lower S-expression to vectorized C99 function~%")
  (format stream "  :dot <expr> [file.dot]      Export saturated e-graph to Graphviz DOT format~%")
  (format stream "  :help                       Display this help message~%")
  (format stream "  :quit or :exit              Exit the interactive session~%~%"))

(defun handle-repl-command (line)
  "Parse and dispatch a single REPL command string."
  (let ((trimmed (string-trim '(#\Space #\Tab) line)))
    (cond
      ((or (string= trimmed ":quit") (string= trimmed ":exit") (string= trimmed ":q"))
       :quit)

      ((or (string= trimmed ":help") (string= trimmed ":h") (string= trimmed ""))
       (print-repl-help)
       :continue)

      ((and (> (length trimmed) 5) (string= (subseq trimmed 0 5) ":sat "))
       (let ((expr (read-from-string (subseq trimmed 5))))
         (format t "[Evaluating Saturation] Input: ~S~%" expr)
         (multiple-value-bind (opt rep)
             (saturate-expr expr (combined-standard-theory) :verbose t)
           (format t "[Result] Optimal: ~S~%" opt)
           (format t "[Telemetry] Iterations: ~D | Nodes: ~D | Classes: ~D | Time: ~,2F ms~%~%"
                   (saturation-report-iterations rep)
                   (saturation-report-nodes rep)
                   (saturation-report-classes rep)
                   (saturation-report-time-ms rep))))
       :continue)

      ((and (> (length trimmed) 6) (string= (subseq trimmed 0 6) ":diff "))
       (let* ((args (read-from-string (format nil "(~A)" (subseq trimmed 6))))
              (expr (first args))
              (var (second args)))
         (format t "[Differentiating] d/d~A for ~S~%" var expr)
         (multiple-value-bind (opt raw rep)
             (differentiate-and-saturate expr var :verbose t)
           (format t "[Raw Gradient] ~S~%" raw)
           (format t "[Optimized Gradient] ~S~%" opt)
           (format t "[Telemetry] Converged: ~A | Time: ~,2F ms~%~%"
                   (saturation-report-converged-p rep)
                   (saturation-report-time-ms rep))))
       :continue)

      ((and (> (length trimmed) 8) (string= (subseq trimmed 0 8) ":emit-c "))
       (let ((expr (read-from-string (subseq trimmed 8))))
         (format t "[Generated C99 Kernel]~%~A~%"
                 (emit-c-function "athanor_generated_kernel" expr '((x . double) (y . double)))))
       :continue)

      (t
       (format t "Unknown command or invalid syntax: ~A. Type :help for usage.~%" trimmed)
       :continue))))

(defun athanor-repl ()
  "Start the Athanor interactive read-eval-print loop."
  (print-repl-banner)
  (loop
    (format t "athanor> ")
    (force-output)
    (let ((line (read-line *standard-input* nil nil)))
      (unless line
        (format t "~%Exiting Athanor.~%")
        (return))
      (handler-case
          (let ((status (handle-repl-command line)))
            (when (eq status :quit)
              (format t "Exiting Athanor.~%")
              (return)))
        (error (c)
          (format t "Error during execution: ~A~%" c))))))
