# Build speed and code size

Load when the build, rebuild or link is slow, the binary is large, or a template change is
about to make any of them worse.

## Measure first

- Build time is a per-developer, per-change cost. A regression in it is a defect.
- Measure three things separately: a full build, an incremental build after touching one
  central header, and the link alone. Different causes, different fixes.
- Clang's `-ftime-trace` gives a per-header, per-function, per-template profile a build
  analyzer ranks. GCC's `-ftime-report` gives per-phase totals. Use them before guessing.
- Two axes: parse cost, the preprocessed size the headers produce, and instantiation cost,
  the templates. The fix differs.
- When a header is suspected, report the preprocessed size. The compiler reads that, not the
  source file.

## Internal linkage, the cheapest big lever

Everything in a `.cpp` file that is not part of the interface belongs in an anonymous
namespace:

```cpp
namespace {
auto helper(std::span<const float> in) -> float { ... }
constexpr int kBlock = 64;
struct Node { ... };
}
```

- The symbol never reaches the object file's external table, so the linker does less and the
  binary is smaller.
- The compiler sees every use, so it can inline, devirtualize, propagate constants, and delete
  the entity when unused.
- Nobody can collide with the name or link against it by accident, so the name can be short.
- Unlike `static`, an anonymous namespace covers types and templates too. `static` on a free
  function is equivalent for the single-function case; a `static` member function is
  unrelated to linkage.

Rules that go with it:

- Never in a header. It produces one distinct copy per including translation unit, bloating
  the binary and giving each translation unit a different object.
- Declare the helper inside the namespace, not only define it. A definition with no
  declaration draws a missing-prototype warning and keeps external linkage.
- Under a unity build, same-named entities from different files collide in one translation
  unit. Keep the names distinct where unity builds are used.
- Hidden visibility (`-fvisibility=hidden` plus export macros) does the same at library level:
  smaller dynamic symbol table, faster linking and loading, more optimization freedom.

## Cut the parse cost

- Include what you use, and only what you use. Every extra include is paid by every consumer,
  transitively.
- Forward declare when only a pointer, a reference or a return type appears.
- Keep the heavy standard headers out of headers: stream, regex, format, chrono formatting,
  ranges. `<iostream>` also injects a static initializer into every including unit.
- Split a monolithic header along what consumers actually need, or every change is a full
  rebuild.
- Pimpl removes the private members and their includes from the header, at one indirection and
  one allocation. An interface class does the same where dynamic dispatch is acceptable.
- Precompiled headers absorb the stable third-party and standard headers. They hide a bad
  dependency graph, they do not fix it.
- Modules (C++20) fix the parse cost properly where the whole toolchain supports them.

## Cut the instantiation cost

- Every distinct instantiation is separate work and separate code. Factor the
  parameter-independent part into a non-template function or base.
- Prefer a constrained overload to a template that compiles all branches.
- Prefer `if constexpr` to a recursive template chain, and a fold expression to recursion.
- `extern template` declares "instantiated elsewhere" in every consumer, with one translation
  unit defining it. The direct fix for a widely included heavy template.
- Type-erase at the boundary when the code need not be generic all the way down. One
  `std::span` or interface parameter can collapse a family of instantiations.
- An always-inline wrapper over a dispatch tree pastes the tree into every call site. Give the
  dispatch its own non-inline function.
- Deep metaprogramming costs compile time superlinearly. Prefer concepts, `index_sequence` and
  fold expressions to hand-rolled recursion.

## Cut the link and the binary

- Export fewer symbols: internal linkage, hidden visibility, no unnecessary `inline` in
  headers.
- A modern parallel linker (`mold`, `lld`, or `gold`) is often the largest incremental-build
  win, and costs one flag.
- Split debug information so the linker does not copy it, and match the level to the build's
  purpose.
- Link-time optimization improves the binary and slows the build. Release only, incremental
  variant preferred.
- Dead code stays unless sections are split and the linker collects them
  (`-ffunction-sections -fdata-sections -Wl,--gc-sections`).
- Static and dynamic linking trade link time for load time. Measure the one that matters.

## Build organization

- Compilation caching turns a rebuild of unchanged code into a copy. Keep it on except when
  measuring compile time.
- Unity builds cut full-build time by removing repeated header parsing, at the cost of worse
  incremental builds and the collisions above. A CI or release tool more than a development
  one.
- Parallelize to what the machine can serve, in jobs and memory. Reduce the job count under
  memory pressure, never by removing what is built.
- Never buy build time by disabling sanitizers, tests, coverage or assertions. The legitimate
  levers are splitting translation units, `extern template`, forward declarations and caching.
- Put the build tree on fast local storage, not a network filesystem.
- Track build time in CI so a regression is visible in the change that caused it.

## How far to take it

- A percentage target is a direction, not a licence. Stop where the next reduction costs
  readability: macro machinery, duplicated declarations, a hand-maintained instantiation list,
  a header layout nobody can follow.
- Take the reductions that also simplify the code and leave the rest: internal linkage, a
  removed include, a factored-out type-independent body.
- Anything that changes what the compiler can see also changes what it can inline,
  devirtualize and constant-fold. Moving a definition out of a header, adding `extern
  template` or hiding a symbol needs the runtime measurement rerun, not only the build time.
