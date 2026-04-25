.PHONY: build run-demo run-core run-optimizer run-logger run-codegen bench-eval bench-memo clean all

EVAL   = eval $$(opam env) &&
DUNE   = $(EVAL) dune

build:
	$(DUNE) build

run-demo: build
	$(DUNE) exec ./demo/demo.exe

run-core: build
	$(DUNE) exec ./examples/app_core_fp.exe

run-optimizer: build
	$(DUNE) exec ./examples/app_optimizer.exe

run-logger: build
	$(DUNE) exec ./examples/app_logger.exe

run-codegen: build
	$(DUNE) exec ./examples/app_codegen.exe

bench-eval: build
	$(DUNE) exec ./benchmarks/bench_eval.exe

bench-memo: build
	$(DUNE) exec ./benchmarks/bench_memo.exe

all: build run-demo run-core run-optimizer run-logger run-codegen bench-eval bench-memo

clean:
	$(DUNE) clean