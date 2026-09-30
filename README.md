# cpp skill

A Claude Code skill for writing, reviewing and modernizing C++.

`skills/cpp/SKILL.md` is a router. It holds the rules that apply to every C++ task, detects the
project's language standard from the build system, and loads one standard reference plus the
topic references the task triggers. Nothing else is inline, so a small task reads little.

```
skills/cpp/SKILL.md                            detection, non-negotiables, red flags, trigger table

  per standard: what it adds, what is still missing and the fallback, the traps
skills/cpp/references/cpp11.md  cpp14.md  cpp17.md  cpp20.md  cpp23.md

  the language
skills/cpp/references/types-and-initialization.md    auto, const/constexpr, enums, casts
skills/cpp/references/functions-and-interfaces.md    passing, returns, overloads, ADL, operators, lambdas
skills/cpp/references/resources-and-ownership.md     RAII, smart pointers, rule of zero/five, views
skills/cpp/references/classes-and-hierarchies.md     value vs entity, virtuals, layout, comparison
skills/cpp/references/errors.md                      strategy, exceptions, safety guarantees, contracts
skills/cpp/references/templates.md                   constraining, compile-time programming, instantiation cost

  using it well
skills/cpp/references/stdlib.md                      containers, algorithms, strings, ranges, utilities
skills/cpp/references/concurrency.md                 threads, atomics, locks, parallel STL, coroutines
skills/cpp/references/numerics.md                    accuracy, tolerances, stability, determinism, RNG
skills/cpp/references/security.md                    safety profiles, untrusted input, hardening flags

  making it fast
skills/cpp/references/performance.md                 lever order, complexity, profiling, layout
skills/cpp/references/simd.md                        portable vector code, dispatch, tails, layout
skills/cpp/references/benchmarking.md                baselines, fixtures, A/B hygiene, reading a result
skills/cpp/references/asm-and-codegen.md             what a listing proves, cost models, counters
skills/cpp/references/memory-and-allocators.md       cache, layout, allocation cost, arenas, pmr
skills/cpp/references/lazy-evaluation-and-proxies.md views, proxies, expression templates, generators

  building and shipping it
skills/cpp/references/source-files.md                headers, ODR, pimpl, ABI, interface evolution
skills/cpp/references/compile-speed.md               internal linkage, includes, instantiation, link, size
skills/cpp/references/build-and-tests.md             warnings, sanitizers, static analysis, tests, CI
skills/cpp/references/portability.md                 compilers, platforms, endianness, conditional compilation

  when things are wrong, old, or constrained
skills/cpp/references/pitfalls.md                    undefined behaviour, lifetime, aliasing, arithmetic
skills/cpp/references/debugging.md                   method, tools, diagnosing common shapes
skills/cpp/references/legacy-and-interop.md          modernization order, C interop in both directions
skills/cpp/references/constrained-environments.md    no exceptions/RTTI/allocation, embedded, real-time, device

  working with people
skills/cpp/references/style-and-comments.md          naming, what a comment is for, formatting, diffs
skills/cpp/references/code-review.md                 review order, what to check, how to phrase it
skills/cpp/references/myths.md                       non-rules, performance folklore, misapplied maxims
```

Sources: the [C++ Core Guidelines](https://isocpp.github.io/CppCoreGuidelines/CppCoreGuidelines),
Herb Sutter's [Elements of Modern C++ Style](https://herbsutter.com/elements-of-modern-c-style/)
and [GotW](https://herbsutter.com/gotw/), Jason Turner's
[C++ Best Practices](https://github.com/cpp-best-practices/cppbestpractices), Andrist and
Sehr's [C++ High Performance, 2nd edition](https://www.oreilly.com/library/view/c-high-performance/9781839216541/),
the OpenSSF [Compiler Options Hardening Guide](https://best.openssf.org/Compiler-Hardening-Guides/Compiler-Options-Hardening-Guide-for-C-and-C++.html),
and [cppreference](https://en.cppreference.com/).

## Install

| Harness | Command |
|---|---|
| Claude Code | `claude plugin marketplace add DiamonDinoia/skill-cpp && claude plugin install cpp@cpp --scope user` |
| Codex CLI | `codex plugin marketplace add DiamonDinoia/skill-cpp`, then `codex plugin add cpp@cpp` |
| Gemini CLI | `gemini extensions install https://github.com/DiamonDinoia/skill-cpp --consent` |
| opencode (by hand, scripted) | `git clone https://github.com/DiamonDinoia/skill-cpp && ./skill-cpp/install-opencode.sh` |
| by hand | `git clone https://github.com/DiamonDinoia/skill-cpp && ln -s "$PWD/skill-cpp/skills/cpp" ~/.claude/skills/cpp` |

The three harnesses with a native manifest carry one in this repository: `.claude-plugin/` for
Claude Code, `.codex-plugin/` for Codex, and `gemini-extension.json` for Gemini CLI. opencode has
no plugin system — `install-opencode.sh` links the skill and the `/cpp` command from a checkout.
Any other harness: install by hand (last row).

Claude Code: in `/plugin`, enable auto-update for the `cpp` marketplace. `claude plugin disable
cpp@cpp` stops the skill. `claude plugin update cpp@cpp` pulls the new release. Claude Code loads
it by name when a task matches its description, or on request: `/cpp`.

## Validation

`test/run.sh` builds a container with each harness, installs the skill with each mechanism and
checks that each harness finds it. A copy with an invalid skill name must fail on the name check.

```sh
test/run.sh   # podman, or: test/run.sh docker
```

## License

MIT.
