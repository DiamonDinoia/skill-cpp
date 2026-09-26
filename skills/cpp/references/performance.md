# Performance

Load for speed, memory traffic, code size or build time, or to review a change claiming any
of them.

## Order of levers

1. Algorithm, in both senses: asymptotic complexity, and how it maps to the hardware
   (memory traffic, cache reuse, branch predictability, vectorizability).
2. Mathematics: fewer operations, a cheaper formulation, the precision the problem needs.
3. Implementation: data layout, allocation, copies, dispatch.

A better implementation of the wrong algorithm is wasted work. Exhaust the higher lever
first.

## Evidence rules

- No performance claim without a profile, hardware counters, or the emitted assembly before
  and after. "Should be faster" is not a result.
- Profile first. Optimizing what the profile does not implicate is churn.
- Report the minimum over repetitions, never the mean. Timing noise only ever adds time.
- Keep an unchanged control in the same run and interleave the variants. A control measured
  yesterday measures yesterday's machine.
- Benchmark the operation the production path elects, at the sizes it uses. A microbenchmark
  of a route nobody takes measures nothing.
- For a localized change read the assembly: spills, instruction mix, vectorization,
  inlining. Wall clock alone cannot attribute a difference.
- Read `benchmarking.md` before designing the timing run, `asm-and-codegen.md` before
  reading a listing.

## Complexity, amortized cost and the constant factor

- Know the complexity of what is called, including the hidden calls: insertion into the
  middle of a vector is linear, a `std::map` lookup is a logarithmic pointer chase, a
  substring search is quadratic in the worst case.
- Amortized constant is not constant per call. `push_back` occasionally reallocates and
  copies, which matters for latency even when the total is fine. `reserve` removes it.
- Complexity ranks algorithms as the input grows. The constant factor decides which wins at
  the size the program uses: a linear scan over a contiguous array beats a tree lookup for
  small n, often for surprisingly large n.
- So pick by complexity, then confirm at the real sizes. Report the crossover, not one size.
- Count what dominates, not source lines: allocations, cache misses, mispredicted branches,
  bytes moved.

## Profiling technique

- Sampling profilers distort least. Use them first, on an optimized build that keeps debug
  information and frame pointers (`-fno-omit-frame-pointer`) so the stacks unwind. Split the
  debug information rather than dropping it.
- Instrumenting profilers give exact call counts and per-call cost, at the price of overhead
  that changes the result. Use them for attribution, not absolute timing.
- Hardware counters answer why: instructions retired, cache misses per level, branch
  mispredictions, stalled cycles, port pressure.
- Profile the real workload with production flags, not a synthetic loop.
- Attribute before optimizing. A profile that blames a leaf function often means the caller
  calls it too often.

## Microbenchmark traps

- The optimizer deletes work whose result is unused. Consume the result through a sink, a
  barrier or a printed accumulator, or the benchmark times an empty loop.
- A constant input lets the compiler fold the computation. Vary it, or hide it behind an
  opaque source.
- A warm, tiny working set hides every memory effect. Size the data to the real case and
  touch it the way the real code does.
- Interleave the variants and repeat. Serial "A then B" records drift, frequency ramp and
  thermal state as a difference between A and B.
- Report the minimum and the spread, so a difference inside the noise shows as such.
- Check the binary under test is the one just built, with production flags.

## Do not pessimize

Free at design time, and not premature optimization:

- Pass expensive types by reference, cheap ones by value.
- `reserve` before a known number of insertions.
- Move instead of copying, and keep move operations `noexcept`.
- Construct in place instead of constructing then copying; `++it`, not `it++`.
- A narrow contract (undefined behaviour on out-of-contract input) buys optimizer freedom;
  pair it with a detectable check.
- Avoid a `shared_ptr` copy on a hot path: two atomic operations.
- Hoist the buffer out of the loop instead of allocating inside it.
- Avoid `std::endl` and `std::function` on hot inner paths; indirect calls also pay CFI
  checks, so cut virtual dispatch first. (C++11)

## Memory is the usual bottleneck

- Contiguity beats indirection. Prefer `std::vector` of values to a container of pointers.
- Choose the layout for the access pattern: structure of arrays for a loop over one field of
  many objects, array of structures for a loop over all fields of one.
- Shrink the working set before optimizing the arithmetic. Fewer bytes touched is fewer
  cache misses and more vector lanes per load.
- Align data when the access requires it, taking the alignment from the property that
  demands it, never from a literal.
- Watch false sharing between threads, and padding waste inside hot structures.
- A narrower integer for state is not automatically faster: it can cost a truncation and a
  re-widening per operation. Narrower wins bandwidth, not arithmetic.

## Compiler and vectorization

- Let the compiler vectorize: simple loops, no aliasing, a known trip count, no early exit,
  no call in the body. Check the vectorization report and the assembly rather than assuming.
- `__restrict` on the destination pointer resolves the common aliasing blocker. On every
  pointer it is a promise that is easy to break. It is not standard C++, so spell it once as
  a project macro.
- Express vectorization through a portable abstraction the project already uses. Per-ISA
  `#ifdef` gates are a portability and maintenance defect. When intrinsics are unavoidable,
  isolate them behind one interface with a scalar fallback and test the two against each
  other. Writing the kernel is `simd.md`.
- A dispatch tree pasted into every call site by an always-inline wrapper multiplies code
  size. Give the dispatch its own function.
- Fast-math flags change results and must never reach a test's reference implementation.
- Prefer a compile-time constant on a hot path: a known trip count, a known size, a
  `constexpr` table.
- Inspect what the optimizer did before and after any change that depends on it. The same
  source compiles differently across compilers and versions.

## Build-time performance

Build time is a cost the whole team pays. Measure it per translation unit before and after a
template-heavy change, and never reduce it by disabling what is built. Levers are in
`compile-speed.md`.

## When to stop

- Stop when the profile no longer shows the code, or the remaining gap is below the noise.
- Do not chase address arithmetic, instruction shuffling or a saved register the profile
  does not implicate. Below the profiler's resolution a rewrite costs readability and buys
  nothing measurable.
- A percentage target is a direction, not a licence for macros, duplication or obscurity.
- Record the number and its conditions outside the source. A benchmark number in a comment
  rots and misleads.

## Related references

- The vector kernel, dispatch and tails: `simd.md`.
- Designing the timing run and defending the number: `benchmarking.md`.
- Emitted code, cost models and counters: `asm-and-codegen.md`.
- Layout, cache behaviour, allocators, footprint: `memory-and-allocators.md`.
- Removing temporaries and intermediate containers: `lazy-evaluation-and-proxies.md`.
- Build time and code size: `compile-speed.md`.
