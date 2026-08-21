# cpp skill

A Claude Code skill for writing, reviewing and modernizing C++.

`cpp/SKILL.md` is a router. It holds the rules that apply to every C++ task, detects the
project's language standard from the build system, and loads one standard reference plus the
topic references the task triggers. Nothing else is inline, so a small task reads little.

```
cpp/SKILL.md                            detection, non-negotiables, red flags, trigger table

  per standard: what it adds, what is still missing and the fallback, the traps
cpp/references/cpp11.md  cpp14.md  cpp17.md  cpp20.md  cpp23.md

  the language
cpp/references/types-and-initialization.md    auto, const/constexpr, enums, casts
cpp/references/functions-and-interfaces.md    passing, returns, overloads, ADL, operators, lambdas
cpp/references/resources-and-ownership.md     RAII, smart pointers, rule of zero/five, views
cpp/references/classes-and-hierarchies.md     value vs entity, virtuals, layout, comparison
cpp/references/errors.md                      strategy, exceptions, safety guarantees, contracts
cpp/references/templates.md                   constraining, compile-time programming, instantiation cost

  using it well
cpp/references/stdlib.md                      containers, algorithms, strings, ranges, utilities
cpp/references/concurrency.md                 threads, atomics, locks, parallel STL, coroutines
cpp/references/numerics.md                    accuracy, tolerances, stability, determinism, RNG
cpp/references/security.md                    safety profiles, untrusted input, hardening flags

  making it fast
cpp/references/performance.md                 lever order, complexity, profiling, layout
cpp/references/simd.md                        portable vector code, dispatch, tails, layout
cpp/references/benchmarking.md                baselines, fixtures, A/B hygiene, reading a result
cpp/references/asm-and-codegen.md             what a listing proves, cost models, counters
cpp/references/memory-and-allocators.md       cache, layout, allocation cost, arenas, pmr
cpp/references/lazy-evaluation-and-proxies.md views, proxies, expression templates, generators

  building and shipping it
cpp/references/source-files.md                headers, ODR, pimpl, ABI, interface evolution
cpp/references/compile-speed.md               internal linkage, includes, instantiation, link, size
cpp/references/build-and-tests.md             warnings, sanitizers, static analysis, tests, CI
cpp/references/portability.md                 compilers, platforms, endianness, conditional compilation

  when things are wrong, old, or constrained
cpp/references/pitfalls.md                    undefined behaviour, lifetime, aliasing, arithmetic
cpp/references/debugging.md                   method, tools, diagnosing common shapes
cpp/references/legacy-and-interop.md          modernization order, C interop in both directions
cpp/references/constrained-environments.md    no exceptions/RTTI/allocation, embedded, real-time, device

  working with people
cpp/references/style-and-comments.md          naming, what a comment is for, formatting, diffs
cpp/references/code-review.md                 review order, what to check, how to phrase it
cpp/references/myths.md                       non-rules, performance folklore, misapplied maxims
```

Sources: the [C++ Core Guidelines](https://isocpp.github.io/CppCoreGuidelines/CppCoreGuidelines),
Herb Sutter's [Elements of Modern C++ Style](https://herbsutter.com/elements-of-modern-c-style/)
and [GotW](https://herbsutter.com/gotw/), Jason Turner's
[C++ Best Practices](https://github.com/cpp-best-practices/cppbestpractices), Andrist and
Sehr's [C++ High Performance, 2nd edition](https://www.oreilly.com/library/view/c-high-performance/9781839216541/),
the OpenSSF [Compiler Options Hardening Guide](https://best.openssf.org/Compiler-Hardening-Guides/Compiler-Options-Hardening-Guide-for-C-and-C++.html),
and [cppreference](https://en.cppreference.com/).

## Install

```sh
ln -s "$PWD/cpp" ~/.claude/skills/cpp         # user-wide
ln -s "$PWD/cpp" <project>/.claude/skills/cpp # single project
```

Claude Code loads it by name when a task matches its description, or on request: `/cpp`.
