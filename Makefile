# Athanor: Equality Saturation & Program Synthesis Kernel Makefile

CC ?= clang
SBCL ?= sbcl
PYTHON ?= python3

.PHONY: all c-lib test bench verify repl clean help

all: c-lib
	@echo "Athanor core systems built successfully."

c-lib:
	$(MAKE) -C c all

test: c-lib
	$(SBCL) --script tests/run-all.lisp

bench: c-lib
	$(PYTHON) tools/bench_suite.py

verify: c-lib
	$(PYTHON) tools/verify_all.py

repl:
	./bin/athanor

clean:
	$(MAKE) -C c clean
	rm -f bin/athanor-bin
	rm -f /tmp/athanor_*
	find . -type f -name "*.fasl" -delete
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true

help:
	@echo "Athanor Build Targets:"
	@echo "  all      - Build native SIMD acceleration shared library"
	@echo "  test     - Run complete 31-module test suite (91 assertions)"
	@echo "  bench    - Run equality saturation and SIMD performance benchmark"
	@echo "  verify   - Run multi-pass automated integrity verification audit"
	@echo "  repl     - Launch interactive Athanor synthesis & superopt shell"
	@echo "  clean    - Remove build artifacts, binaries, and fasl files"
