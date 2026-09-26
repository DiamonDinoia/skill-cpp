# Debugging and diagnosis

Load when something is wrong: a crash, a wrong result, a flaky test, a leak, a hang, or a defect
that appears only in one build configuration.

## Method

1. Reproduce deterministically. Fix the seed, the thread count, the input, the environment. A
   defect that cannot be reproduced cannot be verified as fixed.
2. Minimize. Cut the input and the code path until the failure is one function and a few values.
   Most defects become obvious at that size.
3. Bisect: over commits to find when it broke, over the input to find which record, over the
   flags to find which optimization exposes it.
4. State the hypothesis, then design the observation that would refute it. Changing code until
   the symptom disappears produces a coincidence, not a fix.
5. Fix the cause, add the regression test, then look for the same class elsewhere. A defect that
   appears once usually has siblings.

## What each configuration tells you

- A failure only at `-O2` and not at `-O0` is almost always undefined behaviour. Go to
  `pitfalls.md` and run the undefined-behaviour sanitizer.
- A failure only in a release build may also be an assertion that was doing the work, or an
  `NDEBUG`-dependent code path.
- A failure only under a sanitizer is real. Sanitizers do not invent reports.
- A failure on one compiler or platform only is either undefined behaviour, an unspecified
  evaluation order, or an implementation-defined assumption. See `portability.md`.
- A failure only with multiple threads is a race until proven otherwise. Run the thread
  sanitizer.
- A failure that disappears when a print statement is added is a memory error or a race, and the
  print changed the layout or the timing.

## Tools, in the order they usually pay off

- Sanitizers: address, undefined behaviour, thread, leak. They report the cause with a stack,
  not the symptom.
- Default to a RelWithDebInfo-type build: optimizations stay on, and release crashes stay
  debuggable. For a debug build at optimization, `-Og` plus `-g3` keeps variables visible.
- The debugger: a breakpoint, a watchpoint on the corrupted value, and the backtrace at the
  fault. A watchpoint finds the writer of a corrupted field faster than any amount of reading.
- Core dumps: enable them where the failure happens, and keep the binary and its debug
  information for the exact build.
- Crash-time code runs only async-signal-safe calls out of pre-allocated storage; a signal
  handler that allocates can deadlock under the crash.
- Assertions: a failing assertion close to the cause beats a crash far from it. Add them while
  debugging and keep the ones that document an invariant.
- Logging: structured, levelled, and cheap when disabled. Log decisions and boundary values, not
  every step. A log that must be enabled to reproduce is a timing change.
- The compiler: a stronger warning set, a second compiler, and the optimization reports often
  name the problem directly.
- A compiler crash wants an automated reducer (C-Reduce, llvm-reduce) to a minimal case.
- Static analysis: cheap on the changed files, and it finds what review misses.
- Memory and heap profilers: for leaks, growth and fragmentation.
- `printf` debugging: legitimate, and often fastest, when the environment has no debugger.
  Flush, and remove the statements before committing.

## Diagnosing common shapes

- Crash in a destructor or at exit: a double free, a dangling owner, or a static destruction
  order dependency.
- Wrong result at a boundary only: an off-by-one, an unhandled tail, an alignment assumption, or
  a signed/unsigned conversion.
- Result differs between runs: uninitialized memory, an unordered container's iteration order,
  address-dependent behaviour, or a race.
- Result differs between machines or compilers: floating-point contraction and reassociation, a
  different standard library, or undefined behaviour that happened to work.
- Slow, then suddenly slower: a container reallocating, a hash table degenerating, or the working
  set crossing a cache level.
- Hang: a deadlock from inconsistent lock order, a condition variable without a predicate, or a
  spin waiting on a value that no longer changes.
- Leak the leak checker does not report: a growing container or cache, which is not a leak by
  the checker's definition. Measure the peak footprint instead.

## After the fix

- The regression test must fail on the old code. Verify that, or the test proves nothing.
- Record what was wrong and why it was not caught, and add the check that would have caught it:
  a warning, an assertion, a sanitizer job, a fuzz case.
- Delete the debugging scaffolding: the extra prints, the disabled optimizations, the temporary
  flags.
