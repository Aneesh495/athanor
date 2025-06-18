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
  (let ((name (string-downcase (string tp))))
    (cond
      ((member name '("double-float" "double" "f64") :test #'string=) "double")
      ((member name '("single-float" "float" "f32") :test #'string=) "float")
      ((member name '("integer" "fixnum" "int64" "int64_t" "i64") :test #'string=) "int64_t")
      ((member name '("int" "int32" "int32_t" "i32") :test #'string=) "int32_t")
      ((member name '("uint32" "uint32_t" "u32") :test #'string=) "uint32_t")
      ((member name '("uint64" "uint64_t" "u64") :test #'string=) "uint64_t")
      ((member name '("void") :test #'string=) "void")
      (t "double"))))
