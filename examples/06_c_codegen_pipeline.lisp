;;;; 06_c_codegen_pipeline.lisp - End-to-End Superoptimization and C/JIT Compilation

(in-package #:cl-user)

(load (merge-pathnames "../src/cli/loader.lisp" *load-truename*))

(defpackage #:athanor-example-06
  (:use #:cl #:athanor))

(in-package #:athanor-example-06)

(defun run-example ()
  (format t "========================================================================~%")
  (format t " Example 6: End-to-End Superoptimization & C99/JIT Codegen Pipeline~%")
  (format t "========================================================================~%~%")

  (let ((master (combined-standard-theory)))
    ;; Stage 1: Mathematical Input Expression
    (let ((raw-expr '(+ (* x 16) (* y 8))))
      (format t "[Stage 1] High-level source expression:~%  ~S~%~%" raw-expr)

      ;; Stage 2: Superoptimization via Equality Saturation
      (format t "[Stage 2] Saturated superoptimization under hardware latency cost model...~%")
      (multiple-value-bind (optimized rep)
          (saturate-expr raw-expr master :cost-model :latency)
        (format t "  Optimized AST: ~S~%" optimized)
        (format t "  E-Graph Stats: ~D nodes, ~D classes (iterations: ~D)~%~%"
                (saturation-report-nodes rep)
                (saturation-report-classes rep)
                (saturation-report-iterations rep))
        (assert (equal optimized '(+ (ash x 4) (ash y 3))))

        ;; Stage 3: Dynamic Lisp Machine Code JIT
        (format t "[Stage 3] Compiling to native machine code via SBCL JIT...~%")
        (let ((jit-fn (compile-integer-kernel optimized '(x y))))
          (let ((result (funcall jit-fn 10 5)))
            (format t "  JIT evaluated (fn 10 5) -> ~D (expected 200)~%~%" result)
            (assert (= result 200))))

        ;; Stage 4: C99 Function & SIMD Kernel Emission
        (format t "[Stage 4] Emitting high-performance C99 and OpenMP vector kernels...~%")
        (let ((c-func (emit-c-function 'fast_scale_kernel optimized '((x . int32) (y . int32)) 'int32))
              (simd-kernel (emit-c-vector-kernel 'fast_scale optimized '(x y) "int32_t")))
          (format t "--- Generated C99 Scalar Kernel ---~%~A" c-func)
          (format t "--- Generated OpenMP SIMD Batch Kernel ---~%~A~%" simd-kernel)

          ;; Stage 5: Clang Compilation to Dynamic Native Shared Library
          (format t "[Stage 5] Compiling to dynamic shared library via Clang...~%")
          (let ((dylib-path "/tmp/athanor_generated_kernel.dylib"))
            (compile-c-source-to-shared (format nil "~A~%~A" c-func simd-kernel) dylib-path)
            (format t "  Native shared library successfully produced at: ~A~%" dylib-path)
            (assert (probe-file dylib-path))
            ;; Clean up temporary test library
            (delete-file dylib-path)
            (when (probe-file (format nil "~A.c" dylib-path))
              (delete-file (format nil "~A.c" dylib-path)))
            (format t "  End-to-end pipeline verification completed cleanly.~%")))))))

(run-example)
