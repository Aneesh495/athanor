;;;; athanor.asd - ASDF System Definition for Athanor
;;;; Self-hosting equality saturation superoptimizer, relational synthesis kernel,
;;;; and differentiable S-expression abstract machine.

(asdf:defsystem #:athanor
  :description "Self-hosting equality saturation superoptimizer, relational synthesis kernel, and differentiable S-expression abstract machine."
  :author "Aneesh Krishna <aneeshkrishnaparthasarathy@gmail.com>"
  :license "MIT"
  :version "1.0.0"
  :serial t
  :components
  ((:file "src/package")
   (:file "src/config")
   (:module "core"
    :pathname "src/core"
    :serial t
    :components
    ((:file "types")
     (:file "union-find")
     (:file "hash-cons")
     (:file "enode")
     (:file "eclass")))
   (:module "egraph"
    :pathname "src/egraph"
    :serial t
    :components
    ((:file "egraph")
     (:file "rebuild")
     (:file "analysis")
     (:file "pattern")
     (:file "matcher")
     (:file "ac-match")
     (:file "rules")
     (:file "saturation")
     (:file "extract")))
   (:module "theories"
    :pathname "src/theories"
    :serial t
    :components
    ((:file "ring")
     (:file "bitwise")
     (:file "trig")
     (:file "tensor")
     (:file "boolean")
     (:file "float-stabilize")))
   (:module "logic"
    :pathname "src/logic"
    :serial t
    :components
    ((:file "kanren")
     (:file "clpfd")
     (:file "tabling")
     (:file "datalog")))
   (:module "synth"
    :pathname "src/synth"
    :serial t
    :components
    ((:file "grammar")
     (:file "observational")
     (:file "bottom-up")
     (:file "oracle")
     (:file "cegis")))
   (:module "abstract"
    :pathname "src/abstract"
    :serial t
    :components
    ((:file "domain")
     (:file "interval")
     (:file "sign")
     (:file "affine")
     (:file "interpreter")
     (:file "verifier")))
   (:module "autodiff"
    :pathname "src/autodiff"
    :serial t
    :components
    ((:file "dual")
     (:file "symbolic")
     (:file "tape")
     (:file "jacobian")
     (:file "fused-grad")))
   (:module "codegen"
    :pathname "src/codegen"
    :serial t
    :components
    ((:file "c-ast")
     (:file "emit-c")
     (:file "lisp-jit")
     (:file "cffi-bridge")))
   (:module "cli"
    :pathname "src/cli"
    :serial t
    :components
    ((:file "repl")
     (:file "dot")
     (:file "main")))))
