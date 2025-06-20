;;;; test-framework.lisp - Lightweight Unit Testing Harness for Athanor

(in-package #:cl-user)

(load (merge-pathnames "../src/cli/loader.lisp" *load-truename*))

(defpackage #:athanor-test
  (:use #:cl #:athanor)
  (:export #:deftest
           #:assert-true
           #:assert-false
           #:assert-equal
           #:assert-error
           #:run-all-tests
           #:reset-test-registry
           #:*test-passes*
           #:*test-failures*))

(in-package #:athanor-test)

(defparameter *test-registry* nil
  "List of registered test structures: (name . function).")

(defparameter *test-passes* 0
  "Total number of test assertions passed.")

(defparameter *test-failures* 0
  "Total number of test assertions failed.")

(defstruct (test-case (:constructor make-test-case))
  name
  fn)

(defun reset-test-registry ()
  "Clear registered test cases and reset counters."
  (setf *test-registry* nil
        *test-passes* 0
        *test-failures* 0))

(defmacro deftest (name &body body)
  "Register a named unit test."
  `(let ((tc (make-test-case :name ',name
                             :fn (lambda () ,@body))))
     (setf *test-registry* (remove ',name *test-registry* :key #'test-case-name))
     (push tc *test-registry*)))

(defmacro assert-true (expr &optional (msg nil))
  "Assert that EXPR evaluates to non-nil."
  `(let ((val ,expr))
     (if val
         (incf *test-passes*)
         (progn
           (incf *test-failures*)
           (format t "    [FAIL] Assertion failed: ~S is NIL~@[ (~A)~]~%" ',expr ,msg)))))

(defmacro assert-false (expr &optional (msg nil))
  "Assert that EXPR evaluates to nil."
  `(let ((val ,expr))
     (if (not val)
         (incf *test-passes*)
         (progn
           (incf *test-failures*)
           (format t "    [FAIL] Assertion failed: ~S is non-NIL (~S)~@[ (~A)~]~%" ',expr val ,msg)))))

(defmacro assert-equal (actual expected &optional (msg nil))
  "Assert that ACTUAL equals EXPECTED."
  `(let ((act ,actual)
         (exp ,expected))
     (if (equal act exp)
         (incf *test-passes*)
         (progn
           (incf *test-failures*)
           (format t "    [FAIL] Expected ~S, got ~S for ~S~@[ (~A)~]~%" exp act ',actual ,msg)))))

(defmacro assert-error (form &optional (msg nil))
  "Assert that evaluating FORM raises an error condition."
  `(let ((raised nil))
     (handler-case
         (progn ,form)
       (error () (setf raised t)))
     (if raised
         (incf *test-passes*)
         (progn
           (incf *test-failures*)
           (format t "    [FAIL] Expected error condition from ~S, but evaluated cleanly~@[ (~A)~]~%"
                   ',form ,msg)))))

(defun run-all-tests ()
  "Execute all registered test cases in chronological order and return T on all pass."
  (let ((tests (reverse *test-registry*))
        (suite-start (get-internal-real-time)))
    (format t "========================================================================~%")
    (format t " Running Athanor Master Test Suite (~D registered test modules)~%" (length tests))
    (format t "========================================================================~%")
    (dolist (tc tests)
      (format t "[ RUN  ] ~A~%" (test-case-name tc))
      (let ((prev-fail *test-failures*))
        (handler-case
            (funcall (test-case-fn tc))
          (error (e)
            (incf *test-failures*)
            (format t "    [ERROR] Unhandled condition during ~A: ~A~%"
                    (test-case-name tc) e)))
        (if (= prev-fail *test-failures*)
            (format t "[ PASS ] ~A~%" (test-case-name tc))
            (format t "[ FAIL ] ~A (failures detected)~%" (test-case-name tc)))))
    (let* ((suite-end (get-internal-real-time))
           (elapsed (/ (- suite-end suite-start)
                       (float internal-time-units-per-second 1.0))))
      (format t "========================================================================~%")
      (format t " Test Suite Summary: ~D Passed | ~D Failed | Elapsed: ~,3F s~%"
              *test-passes* *test-failures* elapsed)
      (format t "========================================================================~%")
      (zerop *test-failures*))))
