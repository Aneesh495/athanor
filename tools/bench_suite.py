#!/usr/bin/env python3
"""
bench_suite.py - High-Performance Benchmarking Suite for Athanor

Measures:
  1. Equality saturation throughput across polynomial, trigonometric, and bitwise terms.
  2. AST simplification reduction ratio (initial AST size vs saturated AST size).
  3. Latency comparison and speedup telemetry.
  4. Native C SIMD execution speed and memory bandwidth.
"""

import os
import sys
import time
import subprocess
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parent.parent

def run_lisp_eval(form):
    cmd = [
        "sbcl",
        "--noinform",
        "--non-interactive",
        "--eval", '(load "src/cli/loader.lisp")',
        "--eval", f"(let ((val {form})) (format t \"__BENCH_RESULT__: ~A~%\" val))"
    ]
    proc = subprocess.run(cmd, cwd=ROOT_DIR, capture_output=True, text=True, check=True)
    for line in proc.stdout.splitlines():
        if line.startswith("__BENCH_RESULT__:"):
            return line.replace("__BENCH_RESULT__:", "").strip()
    return None

def benchmark_saturation():
    print("=" * 76)
    print(" Benchmarking Equality Saturation & AST Extraction Telemetry")
    print("=" * 76)

    cases = [
        ("Pythagorean Trigonometric Identity",
         "(+ (expt (sin x) 2) (expt (cos x) 2))"),
        ("Multi-step Bitwise Strength Reduction",
         "(+ (* x 16) (* y 8))"),
        ("Rational Polynomial Zero Cancellation",
         "(* (+ a (- a)) (* b 1))"),
        ("Tensor Contraction GEMM Fusion",
         "(+ (matmul w x) b)"),
        ("Accurate Logarithmic Expansion",
         "(log (+ 1 (expm1 z)))"),
    ]

    print(f"{'Benchmark Target':<42} | {'Init':<5} | {'Opt':<5} | {'Reduction':<10} | {'Time (ms)':<9}")
    print("-" * 76)

    for name, expr_str in cases:
        lisp_bench = f"""
        (labels ((count-ast (x) (if (consp x) (1+ (reduce #'+ (mapcar #'count-ast (cdr x)))) 1)))
          (let* ((master (athanor:combined-standard-theory))
                 (expr '{expr_str})
                 (t0 (get-internal-real-time)))
            (multiple-value-bind (opt rep)
                (athanor:saturate-expr expr master :cost-model :latency)
              (let* ((t1 (get-internal-real-time))
                     (ms (* 1000.0 (/ (- t1 t0) (float internal-time-units-per-second 1.0))))
                     (init-sz (count-ast expr))
                     (opt-sz (count-ast opt)))
                (format nil "~D|~D|~D->~D|~,2F"
                        (athanor:saturation-report-nodes rep)
                        (athanor:saturation-report-classes rep)
                        init-sz opt-sz
                        ms)))))
        """
        raw_res = run_lisp_eval(lisp_bench)
        if raw_res:
            clean = raw_res.strip('"')
            parts = clean.split("|")
            nodes, classes, red, ms = parts[0], parts[1], parts[2], parts[3]
            print(f"{name:<42} | {nodes:<5} | {classes:<5} | {red:<10} | {ms:<9}")

    print("-" * 76)
    print()

def benchmark_c_simd():
    print("=" * 76)
    print(" Benchmarking Native ARM NEON / AVX SIMD Acceleration Engine")
    print("=" * 76)

    c_dir = ROOT_DIR / "c"
    subprocess.run(["make", "all"], cwd=c_dir, capture_output=True, check=True)
    bench_bin = c_dir / "bench"

    proc = subprocess.run([str(bench_bin)], cwd=c_dir, capture_output=True, text=True, check=True)
    for line in proc.stdout.splitlines():
        if "[Athanor SIMD C Benchmark]" in line:
            clean = line.replace("[Athanor SIMD C Benchmark]", "").strip()
            print(f"  * {clean}")
    print("=" * 76)

def main():
    benchmark_saturation()
    benchmark_c_simd()

if __name__ == "__main__":
    main()
