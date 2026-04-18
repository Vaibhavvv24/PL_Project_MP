.PHONY: build run-demo run-core run-optimizer run-logger bench-eval bench-memo clean all

EVAL   = eval $$(opam env) &&
DUNE   = $(EVAL) dune

build:
	$(DUNE) build

run-core: build
	$(DUNE) exec ./examples/app_core_fp.exe

run-optimizer: build
	$(DUNE) exec ./examples/app_optimizer.exe

bench-eval: build
	$(DUNE) exec ./benchmarks/bench_eval.exe

all: build run-core run-optimizer bench-eval

clean:
	$(DUNE) clean
