;;;; cffi-bridge.lisp - Dynamic C Compilation and Shared Library Generation

(in-package #:athanor)

(defparameter *c-compiler* "clang"
  "C compiler executable for dynamic native compilation.")

(defparameter *c-flags* "-O3 -fPIC -shared"
  "Compilation flags for generating optimized native shared libraries.")

(defun compile-c-source-to-shared (c-source-string output-path)
  "Compile C-SOURCE-STRING to native dynamic shared library at OUTPUT-PATH.
   Returns OUTPUT-PATH on success, or signals athanor-error on compilation failure."
  (let* ((c-file (format nil "~A.c" output-path))
         (cmd (format nil "~A ~A -o ~A ~A -lm" *c-compiler* *c-flags* output-path c-file)))
    ;; Write source file to disk
    (with-open-file (out c-file :direction :output :if-exists :supersede :if-does-not-exist :create)
      (format out "#include <stdint.h>~%#include <math.h>~%#include <stddef.h>~%~%~A~%" c-source-string))
    ;; Run compiler command
    (let ((exit-code
            #+sbcl (sb-ext:process-exit-code
                    (sb-ext:run-program "/bin/sh" (list "-c" cmd) :output t :error t))
            #-sbcl 1))
      (if (zerop exit-code)
          output-path
          (error 'athanor-error
                 :message (format nil "C compilation failed for ~A with command: ~A" c-file cmd))))))

(defun compile-expr-to-c-shared (name expr param-types output-path &optional (return-type 'double))
  "Compile S-expression EXPR directly to a native dynamic shared library at OUTPUT-PATH defining function NAME."
  (let ((c-code (emit-c-function name expr param-types return-type)))
    (compile-c-source-to-shared c-code output-path)))

