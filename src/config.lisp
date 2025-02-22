;;;; config.lisp - Global Parameters, Limits, and Configuration Constants

(in-package #:athanor)

;; System Version
(defparameter *athanor-version* "1.0.0"
  "Current version string for the Athanor synthesis and e-graph engine.")

;; Equality Saturation Controls
(defparameter *max-iterations* 30
  "Maximum number of equality saturation iterations before halting.")

(defparameter *node-limit* 50000
  "Upper bound on the total number of e-nodes permitted in an e-graph.")

(defparameter *time-limit-seconds* 10.0
  "Maximum real time in seconds allocated to a single saturation run.")

(defparameter *verbose* nil
  "When non-nil, diagnostic traces and transformation steps are printed to standard output.")

(defparameter *enable-analysis* t
  "Flag indicating whether domain-specific e-class analysis propagation is active.")

;; Synthesis Controls
(defparameter *synthesis-max-depth* 6
  "Maximum term tree depth explored during enumerative bottom-up synthesis.")

(defparameter *synthesis-timeout-seconds* 15.0
  "Timeout for CEGIS synthesis rounds.")

;; Abstract Interpretation Parameters
(defparameter *widening-threshold* 5
  "Number of loop iterations before invoking interval widening operators.")

(defparameter *float-epsilon* 1.0d-12
  "Numerical tolerance threshold for floating point algebraic comparisons.")

;; Default Cost Model
(defparameter *default-cost-model* :ast-size
  "Active cost model used by extraction: :ast-size, :ast-depth, or :latency.")
