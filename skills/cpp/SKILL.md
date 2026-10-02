---
name: cpp
description: Write, review, refactor and modernize C++ against the C++ Core Guidelines. Detects the project's language standard (C++11/14/17/20/23) and loads the matching reference, so no proposed code uses a feature the project cannot compile, then loads the topic reference for the task. Use for any C++ authoring, code review, refactor, modernization pass, API design, performance and memory work, concurrency, numerics, security, debugging, portability, build speed, or "is this idiomatic C++?" question.
license: MIT
---

# Writing C++ properly

This file is the router: the rules for every C++ task, plus what to load. Two loads per
task, the standard reference (§1) and the topic references the task triggers (§4).

## 1. Detect the standard first

Detect before writing or reviewing a line. Stop at the first source that answers.

1. `compile_commands.json`: grep `-std=`. This is what the compiler receives. Check several
   entries, because a project can mix standards per target.
2. CMake: `CMAKE_CXX_STANDARD`, `cxx_std_NN` in `target_compile_features`, `-std=` in
   `CMAKE_CXX_FLAGS` or `target_compile_options`.
3. Other build systems: `cpp_std=` in `meson.build`, `--cxxopt=-std=` in `.bazelrc` or
   `BUILD`, `-std=` in a `Makefile`, `/std:c++NN` in MSVC project files.
4. CI configuration: the compiler versions there cap what the project can use.
5. Source evidence: the newest feature already in use sets a floor, never a ceiling.

Then load exactly one. Each lists what the standard adds, what it replaces, what is missing
with the fallback idiom, and its traps.

| Detected | Reference |
|---|---|
| C++11 | `references/cpp11.md` |
| C++14 | `references/cpp14.md` |
| C++17 | `references/cpp17.md` |
| C++20 | `references/cpp20.md` |
| C++23 or later | `references/cpp23.md` |

- A public header must compile at the lowest standard any consumer uses.
- Never raise the project standard as a side effect. Propose the bump separately, with the
  compilers and CI that support it.
- Language mode does not imply library support. Guard a lagging library feature with a
  feature-test macro from `<version>` (`__cpp_lib_*`, `__cpp_*`).
- If detection is ambiguous, ask. Do not assume the newest standard.

## 2. Non-negotiables

- Correctness first. A fast wrong answer is worthless. Every new branch, route or kernel
  ships with a check that fails when the logic breaks.
- Simplest code that works: fewer lines, fewer types, fewer branches. One general solution
  beats a family of special cases. Answer "is this the simplest thing that achieves the
  goal?" before delivering, not after.
- No feature above the detected standard, and no compiler extension without a stated reason.
- Warning-clean build. Fix the warning, never silence it. `[[maybe_unused]]` for a genuinely
  conditional entity, never a cast to `void`.
- RAII for every resource. No `new`, no `delete`, no owning raw pointer, no manual cleanup.
- Initialize every object at its declaration. Keep every scope minimal.
- Const by default, `constexpr` where the value is computable at compile time.
- Measure before claiming. A performance statement needs a profile, counters or the emitted
  assembly. A correctness statement needs test output.
- Match the project: its naming, formatting and error strategy. Consistency beats any
  external style guide, and the lowest-churn fix comes first.

## 2a. cppman: library fact lookup

Before the skill gives a signature, preconditions or complexity for a standard library
entity, it looks them up in cppman. Find the page name: `cppman -f <name>`. Get the page
text: `cppman '<name>' | cat` (stdout pipe prints, no pager). The source is
cppreference.com, set it with `cppman -s cppreference.com`. A name with no match prints
`error: <name>: nothing appropriate.` and exits 0: try a member name alone. Pages cache in ~/.cache/cppman for offline use. If cppman is missing, say so and give the
install command: `uv tool install cppman`, or `python3 -m pip install --user --upgrade
cppman` when uv is missing. Do not use sudo or a system-wide pip.

## 3. Universal red flags, fix on sight

`new` or `delete` in application code. An owning raw pointer. A C cast. An uninitialized
variable. A magic number. A comment restating the code. A manual index loop an algorithm
covers. A macro a `constexpr` variable, function or template replaces. `using namespace` in
a header. A public data member protected by an invariant. A non-virtual destructor in a
polymorphic base. A function longer than a screen. A `catch (...)` that swallows. An
out-parameter where a return value fits. A copy where a reference or move fits. A
hand-written specialization of an already-generic routine. A view stored beyond the lifetime
of what it views. A file-local helper left with external linkage instead of an anonymous
namespace. An allocation inside a hot loop.

## 4. Topic triggers, load what the task needs

Read the reference when the task or the reviewed code touches its subject. Load several when
the task spans them. Do not load what the task does not touch.

| Trigger | Reference |
|---|---|
| declaring variables, choosing a type, constants, enums, casts, conversions, `auto` | `references/types-and-initialization.md` |
| function signatures, parameter passing, return values, overloads, ADL, operators, lambdas, value categories, API design | `references/functions-and-interfaces.md` |
| allocation, smart pointers, handles, the five special members, views, container ownership, locks as scoped state | `references/resources-and-ownership.md` |
| designing a type, inheritance, virtual functions, polymorphism, layout, comparison, hashing | `references/classes-and-hierarchies.md` |
| error strategy, exceptions, exception safety, `optional`/`expected`, assertions, preconditions | `references/errors.md` |
| any template, concept, trait, metaprogram, or growth in compile time or code size | `references/templates.md` |
| choosing a container, writing a loop, strings, formatting, I/O, or reaching for a hand-rolled utility | `references/stdlib.md` |
| threads, atomics, locks, parallel loops, shared data | `references/concurrency.md` |
| speed, profiling, algorithmic complexity, data layout, or any performance claim | `references/performance.md` |
| writing a vectorized kernel, an instruction-set dispatch, a batch loop, a tail, or code targeting a specific ISA | `references/simd.md` |
| designing a timing run, an A/B, a baseline, a speedup number, a regression check | `references/benchmarking.md` |
| the emitted assembly, whether a loop vectorized or a call inlined, spills, register pressure, a cost model, hardware counters | `references/asm-and-codegen.md` |
| data layout, cache behaviour, allocation cost, custom allocators, `pmr`, alignment, memory footprint | `references/memory-and-allocators.md` |
| discarded temporaries, intermediate containers, view pipelines, proxy objects, expression templates, generators, `co_await` | `references/lazy-evaluation-and-proxies.md` |
| headers, includes, namespaces, ODR, pimpl, library boundaries, ABI, build structure | `references/source-files.md` |
| slow build, slow rebuild, slow link, large binary, internal linkage, visibility, unity builds, `extern template` | `references/compile-speed.md` |
| undefined behaviour, sanitizer reports, lifetime bugs, aliasing, iterator invalidation, integer or floating-point arithmetic, a bug that appears only at `-O2` | `references/pitfalls.md` |
| floating-point accuracy, tolerances, stability, determinism, integer overflow, random numbers | `references/numerics.md` |
| untrusted input, a trust boundary, credentials, hardening flags, a vulnerability class | `references/security.md` |
| a crash, a wrong result, a flaky test, a leak, a hang, a defect in one configuration only | `references/debugging.md` |
| more than one compiler or platform, conditional compilation, endianness, type widths, encodings | `references/portability.md` |
| exceptions or RTTI disabled, no allocation, embedded or freestanding, hard real-time, device code | `references/constrained-environments.md` |
| legacy code, C interop, `extern "C"`, a modernization pass | `references/legacy-and-interop.md` |
| naming, comments, formatting, commit and diff hygiene | `references/style-and-comments.md` |
| warnings, sanitizers, static analysis, tests, CI, what evidence a change needs | `references/build-and-tests.md` |
| the task is to review someone's change rather than write one | `references/code-review.md` |
| a maxim is being applied mechanically, or a "best practice" contradicts the measurement | `references/myths.md` |

Common combinations:

- Numeric work: `numerics.md` plus `pitfalls.md`.
- Optimization: `performance.md` plus `memory-and-allocators.md`, because the bottleneck is
  usually memory. Add `benchmarking.md` before the timing run, `asm-and-codegen.md` before
  reading a listing.
- A parser or any consumer of external data: `security.md` plus `errors.md`.
- A code review: `code-review.md` plus the references for the subject of the change.

If the project disables exceptions or RTTI, forbids allocation, or targets a device or an
embedded platform, load `constrained-environments.md` before proposing any idiom. The
principles hold, the available mechanisms do not.

## 5. Before delivering

1. State the standard detected and the references used.
2. Answer, in the response, "is this the simplest code that achieves the goal?".
3. Name the check that fails if the logic breaks, and run it on the smallest input.
4. Confirm the build is warning-clean and no feature exceeds the detected standard.
5. For a performance change, attach the evidence: profile, counters or assembly, minimum
   over repetitions, against an unchanged control.
6. Leave no comment the code already says, and no engineering notes in the source.

## Sources

- [C++ Core Guidelines](https://isocpp.github.io/CppCoreGuidelines/CppCoreGuidelines) by
  Stroustrup and Sutter: sections P, I, F, C, Enum, R, ES, Per, CP, E, Con, T, CPL, SF, SL,
  the Type, Bounds and Lifetime safety profiles, the NR non-rules, the GSL idioms.
- Herb Sutter, [Elements of Modern C++ Style](https://herbsutter.com/elements-of-modern-c-style/)
  and the [GotW series](https://herbsutter.com/gotw/).
- Jason Turner, [C++ Best Practices](https://github.com/cpp-best-practices/cppbestpractices).
- Andrist and Sehr, [C++ High Performance, 2nd edition](https://www.oreilly.com/library/view/c-high-performance/9781839216541/):
  measurement, data structures, memory management and allocators, compile-time programming,
  proxy objects and lazy evaluation, concurrency, coroutines, parallel algorithms.
- OpenSSF, [Compiler Options Hardening Guide for C and C++](https://best.openssf.org/Compiler-Hardening-Guides/Compiler-Options-Hardening-Guide-for-C-and-C++.html).
- [cppreference](https://en.cppreference.com/) for exact semantics and feature-test macros.
