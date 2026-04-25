# Leveraging Meta-Programming in Functional Programming

## Overview
This project is an academic exploration of **Meta-Programming** within the context of **Functional Programming**, specifically using **OCaml**. It demonstrates how powerful functional techniques like closures and higher-order functions can be combined with runtime and compile-time meta-programming to build optimized Domain-Specific Languages (DSLs) and instrumented systems.

## Key Features

### 1. Core Functional Programming
Located in `src/core_fp/`, this module implements fundamental FP constructs and patterns:
- **First-Class Functions**: Utility for applying and mapping functions.
- **Closures & State**: Practical examples of lexical scope and stateful closures.
- **Function Composition**: Toolsets for pipelines and complex function chains.
- **Higher-Order Functions**: Custom implementations of map, filter, and fold.

### 2. Runtime Arithmetic DSL & Optimizer
Located in `src/runtime_meta/`, this module features a DSL for arithmetic expressions with a sophisticated optimization engine:
- **AST Representation**: A tree-based structure for arithmetic operations and variables.
- **Constant Folding**: Pre-calculates constant expressions (e.g., `3 + 4` → `7`).
- **Algebraic Simplification**: Applies identity and zero laws (e.g., `x + 0` → `x`, `x * 0` → `0`).
- **Strength Reduction**: Replaces expensive operations (e.g., `x * 2` → `x + x`).
- **Pipeline Fixed-Point**: Automatically applies all optimizations until no further changes are possible.
- **Memoization**: A higher-order meta-transformation that caches function results to avoid redundant computation.

### 3. Compile-Time Meta-Programming (PPX)
Located in `src/compiletime_meta/`, this module demonstrates OCaml's powerful preprocessing capabilities:
- **ppx_log**: A custom PPX rewriter that automatically injects entry and exit logs into functions annotated with `[%%log let ...]`.
- **Instrumentation**: Demonstrates how to transform source code at compile time without manual boilerplate.

### 4. Performance Benchmarking
Located in `benchmarks/`, the project includes a suite to measure the impact of meta-programming optimizations:
- **Optimizer Benchmarks**: Demonstrates speedups of over **30,000x** for optimized expression chains.
- **Memoization Benchmarks**: Shows exponential to linear complexity reduction (e.g., Fibonacci speedup of **~60,000x**).

## Installation & Setup

### Prerequisites
- **OCaml** (v4.14+)
- **Opam** (OCaml package manager)
- **Dune** (Build system)

### Setup Environment
Ensure your environment is correctly initialized:
```bash
opam init
eval $(opam env)
```

## Usage

The project uses a `Makefile` for easy interaction.

### Run Everything
Build the project and run all examples and benchmarks:
```bash
make all
```

### Individual Components
- **Core FP Examples**: `make run-core`
- **DSL Optimizer Demo**: `make run-optimizer`
- **PPX Logging Showcase**: `make run-logger`
- **Performance Benchmarks**: `make bench-eval` or `make bench-memo`
- **Clean Build Artifacts**: `make clean`

## Project Structure
```text
.
├── src/
│   ├── core_fp/           # Core Functional Programming logic
│   ├── runtime_meta/      # DSL, Optimizer, and Memoization
│   └── compiletime_meta/  # PPX Rewriters (ppx_log)
├── examples/              # Executable demonstrations
├── benchmarks/            # Performance benchmarking scripts
├── demo/                  # Comprehensive system demo
├── Makefile               # Build and execution targets
└── dune-project           # Project metadata
```
