;;;; run-all.lisp - Master Test Suite Runner for Athanor

(in-package #:cl-user)

(load (merge-pathnames "test-framework.lisp" *load-truename*))
(load (merge-pathnames "test-egraph.lisp" *load-truename*))
(load (merge-pathnames "test-theories.lisp" *load-truename*))
(load (merge-pathnames "test-logic.lisp" *load-truename*))
(load (merge-pathnames "test-synthesis.lisp" *load-truename*))
(load (merge-pathnames "test-abstract.lisp" *load-truename*))
(load (merge-pathnames "test-autodiff.lisp" *load-truename*))
(load (merge-pathnames "test-codegen.lisp" *load-truename*))

(let ((success (athanor-test:run-all-tests)))
  #+sbcl (sb-ext:exit :code (if success 0 1))
  #-sbcl (unless success (error "Test suite failed.")))
