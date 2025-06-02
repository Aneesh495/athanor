;;;; c-ast.lisp - Intermediate Representation for C Target Code Generation

(in-package #:athanor)

(defstruct (c-func (:constructor make-c-func) (:conc-name c-func-))
  "Typed C function definition representation."
  (name "kernel" :type string)
  (return-type "double" :type string)
  (params nil :type list)
  (body nil :type t))

(defun c-type-specifier (tp)
  "Convert symbolic Lisp type specifier to C type string."
  (case tp
    ((double-float double) "double")
    ((single-float float) "float")
    ((integer fixnum int64 int64_t) "int64_t")
    ((int int32 int32_t) "int32_t")
    ((void) "void")
    (otherwise "double")))
