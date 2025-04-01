;;;; package.lisp - Package and Export Definitions for Athanor

(in-package #:cl-user)

(defpackage #:athanor
  (:use #:cl)
  (:export
   ;; Global Configuration & Limits
   #:*athanor-version*
   #:*max-iterations*
   #:*node-limit*
   #:*time-limit-seconds*
   #:*verbose*
   #:*enable-analysis*
   #:*default-cost-model*

   ;; Conditions and Errors
   #:athanor-error
   #:cycle-detected-error
   #:saturation-timeout-error
   #:node-limit-exceeded-error
   #:unification-failure
   #:synthesis-exhausted-error
   #:abstract-domain-error

   ;; Core Union-Find
   #:union-find
   #:make-union-find
   #:uf-find
   #:uf-union
   #:uf-connected-p
   #:uf-count
   #:uf-roots

   ;; Core Hash-Cons & E-Nodes
   #:enode
   #:make-enode
   #:enode-op
   #:enode-children
   #:enode-equal-p
   #:enode-hash
   #:canonicalize-enode
   #:constant-enode-p
   #:enode-to-sexpr

   ;; Core E-Classes
   #:eclass
   #:make-eclass
   #:eclass-id
   #:eclass-nodes
   #:eclass-parents
   #:eclass-data
   #:eclass-size
   #:add-enode-to-eclass
   #:remove-enode-from-eclass

   ;; E-Graph Primitives
   #:egraph
   #:make-egraph
   #:egraph-classes
   #:egraph-hash-cons
   #:egraph-worklist
   #:egraph-clean-p
   #:egraph-add
   #:egraph-add-expr
   #:egraph-merge
   #:egraph-rebuild
   #:in-same-class-p
   #:egraph-class-count
   #:egraph-node-count
   #:lookup-expr
   #:print-egraph-summary

   ;; Analysis Protocol
   #:analysis-domain
   #:analysis-make
   #:analysis-join
   #:analysis-modify
   #:define-analysis
   #:constant-fold-analysis
   #:interval-analysis

   ;; Pattern Language & Matching
   #:pattern
   #:pattern-var-p
   #:parse-pattern
   #:match-pattern
   #:match-all-classes
   #:apply-substitution
   #:pattern-variables

   ;; AC Matching
   #:ac-symbol-p
   #:ac-normalize
   #:match-ac-pattern

   ;; Rewrite Rules & Engine
   #:rule
   #:make-rule
   #:rule-name
   #:rule-lhs
   #:rule-rhs
   #:rule-condition
   #:defrule
   #:rulebase
   #:make-rulebase
   #:add-rule
   #:apply-rules-once

   ;; Equality Saturation
   #:saturation-report
   #:make-saturation-report
   #:saturation-report-iterations
   #:saturation-report-nodes
   #:saturation-report-classes
   #:saturation-report-converged-p
   #:saturation-report-time-ms
   #:saturate
   #:saturate-expr

   ;; Extraction & Cost Models
   #:cost-model
   #:ast-size-cost
   #:ast-depth-cost
   #:latency-cost
   #:extract-best
   #:extract-best-from-class

   ;; Equational Theories
   #:ring-theory
   #:bitwise-theory
   #:trig-theory
   #:tensor-theory
   #:boolean-theory
   #:float-stabilize-theory
   #:combined-standard-theory

   ;; Relational Logic (miniKanren)
   #:var
   #:var-p
   #:make-var
   #:unify
   #:walk
   #:walk*
   #:==
   #:fresh
   #:conde
   #:run
   #:run*
   #:project

   ;; Constraint Logic Programming (CLP(FD))
   #:in-range
   #:distinct-vars
   #:sum-constraint
   #:clpfd-solve

   ;; Tabling & Datalog
   #:define-tabled
   #:datalog-engine
   #:make-datalog-engine
   #:datalog-assert
   #:datalog-retract
   #:datalog-query
   #:datalog-fixpoint

   ;; Inductive Program Synthesis
   #:grammar
   #:make-grammar
   #:add-production
   #:grammar-generate
   #:observational-equivalence-table
   #:make-oe-table
   #:oe-lookup-or-insert
   #:bottom-up-synthesize
   #:cegis-synthesize

   ;; Abstract Interpretation
   #:abstract-domain
   #:interval-domain
   #:make-interval
   #:interval-lo
   #:interval-hi
   #:interval-add
   #:interval-sub
   #:interval-mul
   #:interval-div
   #:interval-intersect
   #:interval-hull
   #:interval-contains-p
   #:sign-domain
   #:sign-abstract
   #:affine-form
   #:make-affine-form
   #:abstract-eval
   #:verify-division-by-zero-free
   #:verify-interval-bounds

   ;; Automatic Differentiation
   #:dual
   #:make-dual
   #:dual-val
   #:dual-dot
   #:dual-add
   #:dual-sub
   #:dual-mul
   #:dual-div
   #:diff-symbolic
   #:grad-symbolic
   #:hessian-symbolic
   #:differentiate-and-saturate

   ;; Codegen & JIT
   #:c-ast
   #:emit-c-expression
   #:emit-c-function
   #:compile-expr-to-lisp
   #:compile-expr-to-c-shared

   ;; CLI & Visualization
   #:athanor-repl
   #:egraph-to-dot
   #:render-egraph-svg))
