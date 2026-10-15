---
name: cpp
description: Use on any C++ task: write, review, refactor, modernize against the C++ Core Guidelines at the detected standard.
license: MIT
---

# Writing C++ properly

Router for every C++ task. Load the standard reference (section 1) and the topic references
the task triggers (section 4). Sources: `references/sources.md`.

## 1. Detect the standard first

Detect before writing or reviewing a line. Stop at the first hit.

1. `compile_commands.json`: grep `-std=`, the flags the compiler receives. Check several entries: a project can mix standards per target.
2. CMake: `CMAKE_CXX_STANDARD`, `cxx_std_NN`, `-std=` in
   `CMAKE_CXX_FLAGS` or `target_compile_options`.
3. Other build systems: `cpp_std=` in `meson.build`, `--cxxopt=-std=` in `.bazelrc` or
   `BUILD`, `-std=` in a `Makefile`, `/std:c++NN` in MSVC project files.
4. CI configuration: its compiler versions cap what the project can use.
5. Source evidence: the newest feature in use sets a floor, never a ceiling.

Load exactly one standard reference (`cpp11.md`, `cpp14.md`, `cpp17.md`, `cpp20.md`, or
`cpp23.md` for C++23 and later). Each lists what the standard adds, what it replaces, what
is missing, the fallback idiom and the traps.

- A public header compiles at the lowest standard any consumer uses.
- Never raise the project standard as a side effect. Propose the bump separately, with supporting compilers and CI.
- Language mode does not imply library support. Guard a lagging library feature with a
  feature-test macro from `<version>` (`__cpp_lib_*`, `__cpp_*`).
- If detection is ambiguous, ask. Do not assume the newest standard.

## 2. Non-negotiables

- Correctness first. Every new branch, route or kernel
  ships with a check that fails when the logic breaks.
- Simplest code that works: fewer lines, types and branches. One general solution beats special cases. Answer "is this the simplest thing that achieves the goal?"
  before delivering.
- No feature above the detected standard, no compiler extension without a stated reason.
- Warning-clean build. Fix the warning, never silence it. `[[maybe_unused]]` for a genuinely
  conditional entity, never a cast to `void`.
- RAII for every resource. No `new`, no `delete`, no owning raw pointer, no manual cleanup.
- Initialize every object at its declaration. Keep scopes minimal.
- Const by default, `constexpr` where computable at compile time.
- Measure before claiming. Speed needs a profile, counters or the emitted
  assembly. Correctness needs test output.
- Match the project: naming, formatting, error strategy. Consistency beats any
  style guide, and the lowest-churn fix comes first.

## 2a. Dead code: measure, then delete

- Delete a helper that became redundant, a guard that can never trigger, a clause that
  restates the check above it. Delete the whole supply chain together: parameter, private
  member, public setter, caller lines, init. Name every removed name in the report. A guard
  whose threshold sits where the code cannot reach is false safety.
- The removal check is the fixture that pins the value the deleted shape fed: the dump that
  forced the new shape fails on the old.
- The upstream default is not safety. A parameter, default or option with no live caller in
  code or tests is an unreferenced definition, not coverage. Grep tests for one hit before
  calling it covered. With an active PR, compare against the PR base and drop what the PR
  added with no other caller.
- A signature left over from the idiom it replaced is wrong for the new one, not stable. Fix
  the signature when the design changes, not later.
- Public-API deletions: check the export set (`git grep` the mangled or declared name).
  Private ones need no check. Say which case each removed name was.

## 2b. cppman: library fact lookup

Before the skill quotes a library signature, preconditions or complexity, it looks them up
in cppman. Find the page: `cppman -f <name>`. Print it:
`cppman '<name>' | cat`. Set the source: `cppman -s cppreference.com`. No match prints
`error: <name>: nothing appropriate.` and exits 0: try a member name alone. Pages cache in
`~/.cache/cppman`. Run the tool check first (tool-check, minimum 0.5.9). Missing or too old: ask
before installing. On a no, continue without cppman and say the lookup did not run.

## 3. Universal red flags, fix on sight

`new` or `delete` in application code. An owning raw pointer. A C cast. An uninitialized
variable. A magic number. A comment restating the code. A manual index loop an algorithm
covers. A macro a `constexpr` variable, function or template replaces. `using namespace` in
a header. A public data member protected by an invariant. A non-virtual destructor in a
polymorphic base. A function longer than a screen. A `catch (...)` that swallows. An
out-parameter where a return value fits. A copy where a reference or move fits. A
hand-written specialization of an already-generic routine. A view stored beyond the lifetime
of what it views. A file-local helper with external linkage, not an anonymous
namespace. An allocation inside a hot loop.

## 4. Topic triggers

Read the `references/<name>.md` the task touches. Load several when the task spans them.
Do not load what the task does not touch.

| Trigger | Reference |
|---|---|
| variables, types, constants, enums, casts, `auto` | types-and-initialization |
| signatures, parameters, returns, overloads, ADL, operators, lambdas, API design | functions-and-interfaces |
| allocation, smart pointers, handles, the five special members, views, ownership, scoped locks | resources-and-ownership |
| type design, inheritance, virtual functions, layout, comparison, hashing | classes-and-hierarchies |
| error strategy, exceptions, `optional`/`expected`, assertions, preconditions | errors |
| templates, concepts, traits, metaprogramming, compile time | templates |
| containers, loops, strings, formatting, I/O, hand-rolled utilities | stdlib |
| threads, atomics, locks, parallel loops, shared data | concurrency |
| speed, profiling, complexity, a performance claim | performance |
| vectorized kernels, ISA dispatch, batch loops, tails | simd |
| timing runs, A/B, baselines, speedups, regression checks | benchmarking |
| assembly, vectorization, inlining, spills, register pressure, hardware counters | asm-and-codegen |
| data layout, cache, allocation cost, allocators, `pmr`, alignment | memory-and-allocators |
| temporaries, view pipelines, proxies, expression templates, generators, `co_await` | lazy-evaluation-and-proxies |
| headers, includes, namespaces, ODR, pimpl, ABI, build structure | source-files |
| slow build or link, large binary, visibility, unity builds, `extern template` | compile-speed |
| undefined behaviour, sanitizers, lifetime, aliasing, iterator invalidation, `-O2`-only bugs | pitfalls |
| floating point, tolerances, determinism, integer overflow, random numbers | numerics |
| untrusted input, trust boundaries, credentials, hardening, vulnerabilities | security |
| crashes, wrong results, flaky tests, leaks, hangs, single-configuration defects | debugging |
| multiple compilers or platforms, conditional compilation, endianness, encodings | portability |
| no exceptions or RTTI, no allocation, embedded, freestanding, real-time, device code | constrained-environments |
| legacy code, C interop, `extern "C"`, modernization | legacy-and-interop |
| naming, comments, formatting, commit and diff hygiene | style-and-comments |
| warnings, sanitizers, static analysis, tests, CI, evidence | build-and-tests |
| reviewing someone's change | code-review |
| a maxim applied mechanically, best practice contradicting measurement | myths |
| clang-tidy, tool version checks, tool installs | lint, tool-check |

Combinations. Numeric work: numerics plus pitfalls. Optimization: performance plus
memory-and-allocators, benchmarking before timing, asm-and-codegen before listings. External
data: security plus errors. Reviews: code-review plus the subject references.

If the project disables exceptions or RTTI, forbids allocation or targets a device, load
constrained-environments before proposing any idiom. The principles hold, the mechanisms do not.

## 5. Before delivering

1. State the detected standard and the references used.
2. Answer "is this the simplest code that achieves the goal?".
3. Name the check that fails if the logic breaks. Run it on the smallest input.
4. Lint every C++ file written or edited (lint).
5. Confirm a warning-clean build and no feature above the detected standard.
6. A performance change attaches evidence: profile, counters or assembly, minimum over
   repetitions, against an unchanged control.
7. Leave no comment the code already says, no engineering notes in the source.
