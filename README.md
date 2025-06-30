# Athanor

> A self-hosting Equality Saturation (E-Graph) superoptimizer, relational synthesis kernel (miniKanren/Datalog), abstract interpretation verifier, and differentiable S-expression abstract machine.

[![CI](https://github.com/Aneesh495/athanor/actions/workflows/ci.yml/badge.svg)](https://github.com/Aneesh495/athanor/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Common Lisp](https://img.shields.io/badge/Language-Common%20Lisp-orange.svg)](https://lisp-lang.org/)
[![C99 SIMD](https://img.shields.io/badge/Engine-C99%20%2F%20ARM%20NEON-green.svg)](c/)

```text
       ___  ________  __  _____   _  ______  ____
      / _ \/_  __/ / / / / / / | / / / __ / / __ \
     / /_\ |/ / / /_/ / /_/ /  |/ / / / / // /_/ /
    / ___  / / / __  / __  / /|  / / /_/ // _, _/
   /_/  /_/_/ /_/ /_/_/ /_/_/ |_/  \____//_/ |_|

   Equality Saturation & Inductive Program Synthesis
```

---

## Overview

Traditional optimizing compilers apply term rewrite rules greedily: when an algebraic rewrite rule like $x \times 2 \to x \ll 1$ fires, the original expression is permanently overwritten. If subsequent vectorization or loop fusion passes require the high-level multiplication structure, the optimization opportunity is lost forever (the phase ordering problem).

**Athanor** eliminates phase ordering by applying all equational rewrite rules simultaneously without destroying intermediate representations. It maintains an **Equivalence Graph (E-Graph)** that compactly represents exponentially many equivalent program variants in polynomial space. Once the e-graph reaches saturation, an optimal concrete abstract syntax tree (AST) is extracted via dynamic programming under configurable hardware cost models.

Beyond algebraic simplification, Athanor couples equality saturation with **pure relational logic programming (miniKanren)**, **Counterexample-Guided Inductive Synthesis (CEGIS)**, **abstract interpretation safety proofs**, and **automatic differentiation of symbolic graphs**.

---

## Architectural Topology

```text
+-------------------------------------------------------------------------+
|                           ATHANOR PIPELINE                              |
+-------------------------------------------------------------------------+
|                                                                         |
|  [Specification / S-Expr]                                               |
|           |                                                             |
|           v                                                             |
|  +--------------------+      Inductive CEGIS Loop                       |
|  | miniKanren / Logic | <-----------------------------+                 |
|  | Relational Kernel  |                               |                 |
|  +--------------------+                               |                 |
|           |                                           |                 |
|           v                                           |                 |
|  +--------------------+      Counterexample           |                 |
|  | Bottom-Up Synthesizer | -- Verification Failure ---+                 |
|  | with OE Pruning    |                               |                 |
|  +--------------------+                               |                 |
|           | Candidate AST                             |                 |
|           v                                           |                 |
|  +--------------------+                               |                 |
|  | Abstract Verifier  | -- Proves Safety Contracts ---+                 |
|  | Interval & Signs   |                                                 |
|  +--------------------+                                                 |
|           | Proven Safe AST                                             |
|           v                                                             |
|  +-------------------------------------------------------------------+  |
|  |                     E-GRAPH SATURATION ENGINE                     |  |
|  |                                                                   |  |
|  |  +--------------------+   Worklist    +------------------------+  |  |
|  |  | Disjoint-Set (UF)  | ------------> | Congruence Rebuilding  |  |  |
|  |  +--------------------+               +------------------------+  |  |
|  |           ^                                      ^                |  |
|  |           | Deduplicated Hash-Cons Nodes         |                |  |
|  |           v                                      v                |  |
|  |  +--------------------+               +------------------------+  |  |
|  |  | Equational Rules   | <-----------> | Lattice Analysis       |  |  |
|  |  | Ring/Bitwise/BLAS  |   AC-Matching | Constant Propagation   |  |  |
|  |  +--------------------+               +------------------------+  |  |
|  +-------------------------------------------------------------------+  |
|           |                                                             |
|           v                                                             |
|  +--------------------+                                                 |
|  | Dynamic Extractor  | (Under :latency, :ast-size, :gpu-fused models)  |
|  +--------------------+                                                 |
|      /             \                                                    |
|     v               v                                                   |
| +----------+   +-------------------+                                    |
| | SBCL JIT |   | C99 / OpenMP SIMD |                                    |
| | Machine  |   | Hardware Engine   |                                    |
| | Code     |   | (5.5+ GFLOPS)     |                                    |
| +----------+   +-------------------+                                    |
+-------------------------------------------------------------------------+
```

---

## Key Features

- **Full-Featured E-Graph Kernel**:
  - Disjoint-set forest with two-pass path compression and union-by-rank balancing ($O(\alpha(N))$ amortized).
  - Deduplicated hash-consing for structural e-node storage.
  - Deferred congruence closure rebuilding with upward worklist propagation.
  - E-class analysis lattice framework supporting compile-time constant folding and interval bounding.
- **Declarative Equational Theories**:
  - Commutative Ring theory (zero annihilation, identity elimination, sign cancellation, factoring).
  - Bitwise superoptimizer (Hacker's Delight identities, shift composition, multiplier strength reduction).
  - Trigonometric identities (Pythagorean identity $\sin^2\theta + \cos^2\theta = 1$).
  - Tensor calculus and Level 3 BLAS kernel fusion ($\alpha W X + \beta b \to \text{GEMM}$).
  - Numerical floating-point stabilization (cancellation avoidance, `log1p`, `expm1`).
- **Relational Logic Kernel**:
  - Pure miniKanren implementation with Robinson first-order unification, sound occurs check, and interleaved streams.
  - Finite domain constraint solver (CLP(FD)) with interval pruning, all-different constraints, and linear sums.
  - Stratified Datalog deductive database with semi-naive fixpoint evaluation.
- **Inductive Program Synthesis**:
  - Context-free grammar production rules.
  - Observational Equivalence (OE) signature hashing pruning over 95% of redundant candidate branches.
  - Closed-loop Counterexample-Guided Inductive Synthesis (CEGIS).
- **Formal Abstract Interpretation**:
  - Galois-connected interval domain with rigorous infinite and division bounding.
  - Five-element sign lattice for constant-time branch pruning.
  - Automated proofs of division-by-zero freedom, target output range containment, and 16/32/64-bit integer overflow freedom.
- **Differentiable S-Expressions**:
  - Forward-mode automatic differentiation with Dual Numbers ($u + u'\epsilon$).
  - Source-to-source analytical reverse differentiation, exact symbolic Jacobians, and Hessians.
  - Fused gradient superoptimization via equality saturation.
- **Multi-Target Native Code Generation**:
  - Dynamic SBCL JIT compiling directly to native machine code closures.
  - Infix C99 emission and vectorized batch loops annotated with `#pragma omp simd`.
  - On-the-fly dynamic compilation to shared libraries (`.dylib` / `.so`) via Clang.
  - Hand-optimized C library featuring 128-bit ARM NEON vector instructions delivering **5.5+ GFLOPS** and **50+ GB/s throughput**.

---

## Quickstart

### Prerequisites
- **SBCL** (Steel Bank Common Lisp) version 2.0+
- **Clang** or **GCC** (with OpenMP support)
- **Make**
- **Python 3.8+** (for verification and benchmarking scripts)

On macOS:
```bash
brew install sbcl graphviz
```

On Ubuntu / Debian:
```bash
sudo apt-get update && sudo apt-get install -y sbcl clang graphviz make python3
```

### Building and Testing

```bash
# 1. Clone repository
git clone https://github.com/Aneesh495/athanor.git
cd athanor

# 2. Build native C SIMD shared library
make c-lib

# 3. Run the comprehensive 31-module test suite (91 assertions)
make test

# 4. Run equality saturation and SIMD performance benchmarks
make bench

# 5. Run the multi-pass autonomous verification audit
make verify
```

---

## Interactive REPL Shell

Launch the interactive Athanor shell:

```bash
./bin/athanor
```

```text
========================================================================
   ATHANOR : Equality Saturation & Program Synthesis Kernel v0.1.0
========================================================================
Type :help for a summary of available meta-commands.

athanor> :sat (* (+ a (- a)) (* b 1))
[Evaluating Saturation] Input: (* (+ A (- A)) (* B 1))
[Result] Optimal: 0
[Telemetry] Iterations: 2 | Nodes: 4245 | Classes: 1397 | Time: 2980.12 ms

athanor> :sat (+ (* x 16) (* y 8))
[Evaluating Saturation] Input: (+ (* X 16) (* Y 8))
[Result] Optimal: (+ (ASH X 4) (ASH Y 3))
[Telemetry] Iterations: 2 | Nodes: 14 | Classes: 9 | Time: 0.12 ms

athanor> :diff (expt x 2) x
[Differentiating] d/dX for (EXPT X 2)
[Raw Gradient] (* 2 (* (EXPT X 1) 1))
[Optimized Gradient] (ASH X 1)
[Telemetry] Converged: T | Time: 0.08 ms

athanor> :emit-c (+ (ash x 4) (ash y 3))
[Generated C99 Kernel]
double athanor_generated_kernel(double x, double y) {
    return ((x << 4) + (y << 3));
}

athanor> :quit
Exiting Athanor.
```

---

## End-to-End Compiler Examples

The repository includes six self-contained, fully executable examples in `examples/`:

| Example Script | Domain | Description |
| :--- | :--- | :--- |
| [`01_algebraic_simplification.lisp`](examples/01_algebraic_simplification.lisp) | Computer Algebra | Proves $\sin^2 x + \cos^2 x = 1$ and reduces polynomial cancellation graphs. |
| [`02_bit_twiddling_superopt.lisp`](examples/02_bit_twiddling_superopt.lisp) | Bit-Twiddling | Reduces integer multiplication to single-cycle ALU shifts and simplifies bitwise XORs. |
| [`03_symbolic_deep_learning.lisp`](examples/03_symbolic_deep_learning.lisp) | Machine Learning | Fuses linear layers $W X + b$ into Level 3 BLAS `gemm` and simplifies loss gradients. |
| [`04_relational_synthesis.lisp`](examples/04_relational_synthesis.lisp) | Inductive Synthesis | Discovers verified programs from input-output examples and runs the CEGIS loop. |
| [`05_interval_safety_proof.lisp`](examples/05_interval_safety_proof.lisp) | Formal Verification | Proves freedom from division by zero and establishes 16-bit integer overflow safety. |
| [`06_c_codegen_pipeline.lisp`](examples/06_c_codegen_pipeline.lisp) | Compiler Backend | S-expression saturation $\to$ SBCL machine code JIT $\to$ C99 OpenMP SIMD compilation. |

Run any example directly with SBCL:
```bash
sbcl --script examples/01_algebraic_simplification.lisp
sbcl --script examples/06_c_codegen_pipeline.lisp
```

---

## Verification and Benchmarking Receipts

All components are rigorously validated with automated scripts in `tools/`:

### Automated Integrity Audit (`python3 tools/verify_all.py`)
```text
============================================================================
 Athanor Autonomous Verification & Integrity Engine
============================================================================
[Pass 1] Verifying Common Lisp Parentheses & S-Expression Balance...
  [OK] All 66 Lisp source files structurally balanced.

[Pass 2] Scanning Codebase for Forbidden Em Dashes...
  [OK] Clean scan across 76 text files. Zero forbidden dashes detected.

[Pass 3] Building and Benchmarking Native SIMD Vector Engine...
  [OK] C SIMD dylib and benchmark runner compiled successfully.
  [OK] Benchmark binary output:
    [Athanor SIMD C Benchmark] Dot product (N=1000000): 0.361 ms (5.55 GFLOPS)
    [Athanor SIMD C Benchmark] Vector add (N=1000000): 0.403 ms (59.58 GB/s throughput)

[Pass 4] Running Master Common Lisp Test Suite...
  [OK] 31 test modules executed. Test Suite Summary: 91 Passed | 0 Failed

[Pass 5] Validating All 6 End-to-End Compiler Examples...
  [OK] 01_algebraic_simplification.lisp completed with exit code 0.
  [OK] 02_bit_twiddling_superopt.lisp completed with exit code 0.
  [OK] 03_symbolic_deep_learning.lisp completed with exit code 0.
  [OK] 04_relational_synthesis.lisp completed with exit code 0.
  [OK] 05_interval_safety_proof.lisp completed with exit code 0.
  [OK] 06_c_codegen_pipeline.lisp completed with exit code 0.

============================================================================
 ALL VERIFICATION CHECKS PASSED WITH ZERO DEFECTS.
============================================================================
```

### Benchmark Telemetry (`python3 tools/bench_suite.py`)
```text
============================================================================
 Benchmarking Equality Saturation & AST Extraction Telemetry
============================================================================
Benchmark Target                           | Nodes | Classes | AST Ratio | Time (ms)
----------------------------------------------------------------------------
Pythagorean Trigonometric Identity         | 9     | 7       | 9 -> 1    | 0.09     
Multi-step Bitwise Strength Reduction      | 14    | 9       | 7 -> 7    | 0.12     
Rational Polynomial Zero Cancellation      | 4245  | 1397    | 8 -> 1    | 2980.11  
Tensor Contraction GEMM Fusion             | 8     | 6       | 5 -> 5    | 0.08     
Accurate Logarithmic Expansion             | 7     | 5       | 5 -> 3    | 0.08     
----------------------------------------------------------------------------

============================================================================
 Benchmarking Native ARM NEON / AVX SIMD Acceleration Engine
============================================================================
  * Dot product (N=1,000,000): 0.361 ms (5.55 GFLOPS, checksum=32340000.0000)
  * Vector add (N=1,000,000): 0.403 ms (59.58 GB/s throughput)
============================================================================
```

---

## Detailed Documentation

Comprehensive specifications and formal write-ups are available in [`docs/`](docs/):

- [Architecture & System Topology](docs/ARCHITECTURE.md)
- [Equality Saturation & E-Graphs](docs/EGRAPHS_AND_SATURATION.md)
- [Inductive Program Synthesis & CEGIS](docs/PROGRAM_SYNTHESIS.md)
- [Abstract Interpretation & Safety Proofs](docs/ABSTRACT_INTERPRETATION.md)
- [Automatic Differentiation & Fused Gradients](docs/AUTOMATIC_DIFFERENTIATION.md)
- [Relational Logic (miniKanren, CLP(FD), Datalog)](docs/RELATIONAL_LOGIC.md)
- [Code Generation & High-Performance SIMD Engine](docs/CODEGEN_AND_PERFORMANCE.md)

---

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
