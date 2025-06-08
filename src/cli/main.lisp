;;;; main.lisp - Command-Line Interface Dispatcher and Top-Level Entry Point

(in-package #:athanor)

(defun print-usage (&optional (stream t))
  "Print CLI usage options and parameter descriptions."
  (format stream "Usage: athanor [OPTIONS]~%~%")
  (format stream "Options:~%")
  (format stream "  --help, -h               Print this help message and exit~%")
  (format stream "  --version, -v            Print system version and exit~%")
  (format stream "  --repl                   Launch the interactive Athanor shell (default)~%")
  (format stream "  --sat <expr>             Run equality saturation on EXPR and print result~%")
  (format stream "  --diff <expr> <var>      Compute superoptimized analytical derivative~%")
  (format stream "  --emit-c <expr>          Compile EXPR to C99 and print source code~%")
  (format stream "  --test                   Execute system verification test suite~%~%"))

(defun cli-main (&optional (args nil))
  "Top-level entry point called from command line launcher."
  (let ((cmd-args (or args
                      #+sbcl (cdr sb-ext:*posix-argv*)
                      #-sbcl nil)))
    (let ((exit-code
            (cond
              ((or (null cmd-args) (member "--repl" cmd-args :test #'string=))
               (athanor-repl)
               0)

              ((or (member "--help" cmd-args :test #'string=)
                   (member "-h" cmd-args :test #'string=))
               (print-usage)
               0)

              ((or (member "--version" cmd-args :test #'string=)
                   (member "-v" cmd-args :test #'string=))
               (format t "Athanor version ~A~%" *athanor-version*)
               0)

              ((member "--sat" cmd-args :test #'string=)
               (let* ((idx (position "--sat" cmd-args :test #'string=))
                      (expr-str (nth (1+ idx) cmd-args)))
                 (if expr-str
                     (let ((expr (read-from-string expr-str)))
                       (multiple-value-bind (opt rep)
                           (saturate-expr expr (combined-standard-theory))
                         (format t "~S~%" opt)
                         (when *verbose*
                           (format t "[Telemetry] Iterations: ~D | Nodes: ~D | Time: ~,2F ms~%"
                                   (saturation-report-iterations rep)
                                   (saturation-report-nodes rep)
                                   (saturation-report-time-ms rep)))
                         0))
                     (progn
                       (format *error-output* "Error: --sat requires an expression argument.~%")
                       1))))

              ((member "--diff" cmd-args :test #'string=)
               (let* ((idx (position "--diff" cmd-args :test #'string=))
                      (expr-str (nth (1+ idx) cmd-args))
                      (var-str (nth (+ idx 2) cmd-args)))
                 (if (and expr-str var-str)
                     (let ((expr (read-from-string expr-str))
                           (var (read-from-string var-str)))
                       (multiple-value-bind (opt raw rep)
                           (differentiate-and-saturate expr var)
                         (declare (ignore raw rep))
                         (format t "~S~%" opt)
                         0))
                     (progn
                       (format *error-output* "Error: --diff requires <expr> and <var> arguments.~%")
                       1))))

              ((member "--emit-c" cmd-args :test #'string=)
               (let* ((idx (position "--emit-c" cmd-args :test #'string=))
                      (expr-str (nth (1+ idx) cmd-args)))
                 (if expr-str
                     (let ((expr (read-from-string expr-str)))
                       (format t "~A~%" (emit-c-function "athanor_kernel" expr '((x . double) (y . double))))
                       0)
                     (progn
                       (format *error-output* "Error: --emit-c requires an expression argument.~%")
                       1))))

              (t
               (format *error-output* "Unrecognized command-line argument: ~S~%" (car cmd-args))
               (print-usage *error-output*)
               1))))
      #+sbcl (unless (or (null cmd-args) (member "--repl" cmd-args :test #'string=))
               (sb-ext:exit :code exit-code))
      exit-code)))
