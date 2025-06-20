;;;; test-codegen.lisp - C99/SIMD Emission and SBCL/Clang Native Compilation Tests

(in-package #:athanor-test)

(deftest test-emit-c-expressions
  (let ((c-add (emit-c-expression '(+ a b)))
        (c-mul (emit-c-expression '(* x y)))
        (c-ash (emit-c-expression '(ash x 4))))
    (assert-equal c-add "(a + b)")
    (assert-equal c-mul "(x * y)")
    (assert-equal c-ash "(x << 4)")))

(deftest test-emit-c-functions-and-kernels
  (let ((fn-str (emit-c-function 'poly_eval '(+ (expt x 2) 1.0) '((x . double)) 'double))
        (vec-str (emit-c-vector-kernel 'vec_poly '(+ x 1.0) '(x) "double")))
    (assert-true (search "double poly_eval(double x)" fn-str))
    (assert-true (search "#pragma omp simd" vec-str))
    (assert-true (search "vec_poly_batch" vec-str))))

(deftest test-sbcl-jit-compilation
  ;; Compile double-float function f(x, y) = x*y + 2.5
  (let ((fn (compile-expr-to-lisp '(+ (* x y) 2.5d0) '(x y))))
    (assert-true (functionp fn))
    (let ((val (funcall fn 3.0d0 4.0d0)))
      (assert-equal val 14.5d0)))
  ;; Compile 64-bit integer function f(a, b) = (a << 3) ^ b
  (let ((int-fn (compile-integer-kernel '(logxor (ash a 3) b) '(a b))))
    (assert-true (functionp int-fn))
    (let ((val (funcall int-fn 2 1)))
      ;; (2 << 3) = 16, 16 ^ 1 = 17
      (assert-equal val 17))))

(deftest test-dynamic-clang-shared-compilation
  (let* ((c-src "int32_t add_three(int32_t a, int32_t b, int32_t c) { return a + b + c; }")
         (out-path "/tmp/athanor_test_unit.dylib"))
    (compile-c-source-to-shared c-src out-path)
    (assert-true (probe-file out-path))
    ;; Clean up test artifact
    (delete-file out-path)
    (when (probe-file (format nil "~A.c" out-path))
      (delete-file (format nil "~A.c" out-path)))))
