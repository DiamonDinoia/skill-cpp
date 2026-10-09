# Warnings, sanitizers, tests and tooling

Load when configuring a build, adding tests, setting up CI, or deciding what evidence a
change needs.

## Warnings

- Warnings as errors in every build developers and CI run. A warning nobody reads is a defect
  report nobody reads.
- Enable a wide set. This baseline, from the C++ Best Practices list, subsumes most project
  lists:

```
-Wall -Wextra -Wpedantic -Wshadow -Wnon-virtual-dtor -Wold-style-cast -Wcast-align
-Wunused -Woverloaded-virtual -Wconversion -Wsign-conversion -Wdouble-promotion
-Wmisleading-indentation -Wnull-dereference -Wformat=2 -Wimplicit-fallthrough
-Wduplicated-cond -Wduplicated-branches -Wlogical-op -Wuseless-cast   # last four: GCC only
/permissive- /W4 /w14640 /w14242 /w14254 /w14263 /w14265 /w14287 /we4289 /w14296 /w14311
/w14545 /w14546 /w14547 /w14549 /w14555 /w14619 /w14826 /w14905 /w14906 /w14928  # MSVC
```

- Fix the warning, never silence it. `[[maybe_unused]]` for a genuinely conditional entity,
  never a cast to `void`.
- Suppress only locally, with a scoped pragma and a one-line reason, never project-wide.
- Silence third-party headers by including them as system headers (`-isystem`,
  `/external:anglebrackets /external:W0`), not by disabling the warning.

## Sanitizers and dynamic analysis

- Address and undefined-behaviour sanitizers on the test build, thread sanitizer wherever
  concurrency exists. They find what review does not.
- Too slow for the default build means a CI job that runs the tests under them, not deletion.
- A leak checker on the test binary catches the failure paths the success path hides.
- Fuzz any parser or consumer of untrusted input, with libFuzzer or AFL++. A fuzzer plus a
  sanitizer finds a class of defects unit tests do not.
- Valgrind remains useful where the sanitizers cannot be built, at a higher cost.

## Static analysis

- `clang-tidy` with `bugprone-*`, `performance-*`, `readability-*`, `modernize-*` and
  `cppcoreguidelines-*`, tuned once and then enforced.
- Keep `modernize-*` on and apply its fixes. Record which checks are off, and why.
- `cppcheck` finds a different set than `clang-tidy`, and `include-what-you-use` fixes the
  include graph mechanically. Both are cheap to add once.
- Run the analyzer on the changed files in CI, so the baseline never regresses.
- A second compiler in CI is a static analyzer too: each diagnoses what the other misses.

## Tests

- Every new branch, route, kernel or error path gets a test. The check is the deliverable.
- Use the framework the project already has, or Catch2, GoogleTest or doctest. Never a
  hand-rolled harness.
- Write the smallest test that fails when the logic breaks. A test that passes on wrong code
  is worse than none, because it removes the pressure to check.
- Never `#define private public` to pry class internals open for a unit test; the macro also blinds static analysis.
- Use a real oracle: an analytical result, a reference implementation, an invariant, a round
  trip. Comparing an implementation to itself proves nothing.
- Numerical code compares against a tolerance derived from the error bound, not a guess, and
  the reference is not compiled with fast-math.
- Test the boundaries: zero, one, the maximum, an empty container, an unaligned size, the
  size just past a vectorized block.
- Test the failure paths, with injected failures.
- Verify the assertions actually ran. A test that reports nothing on success is not evidence.
- Keep tests deterministic: fixed seeds, no wall-clock dependence, no reliance on unordered
  container order.
- Keep unit tests hermetic: no database, network, file system or environment dependence. A test that needs them is not a unit test.
- Keep the suite fast enough to run on every change. Move exhaustive sweeps to a scheduled
  job.
- Test that un-compilable code fails to compile: an expect-fail snippet built with the project's own flags.
- One test of `constexpr` code runs at compile time inside a `static_assert` and at run time as a normal call.
- Measure coverage (`gcov` with `lcov` or `gcovr`, or the platform equivalent) to find the
  untested branch. Read the next section before treating a number as a result.

## Checks that silently prove nothing

Each passes while the property it appears to test is broken.

- A weak invariant is not a correctness check. Conserved quantity and norm preservation pass
  on a permuted, sign-flipped or conjugated result. Pair each with a strong check: an
  element-wise comparison against a reference, or a round trip.
- Tightening a tolerance breaks the generator first. When the tightened test fails, suspect
  the reference and the input generator before the code: both were built to the looser
  standard.
- A reference must not share the code's aggressive flags. Fast-math or contraction applied to
  a whole target reaches the reference too, making the comparison self-consistent rather than
  correct.
- A bit-exact hash detects a changed value, never a changed schedule. It cannot see
  result-preserving reordering, and it false-alarms on any legal recompilation.
- A "custom parameter" test that passes the default exercises nothing. Assert the value
  differs from the default, or the plumbing can be missing entirely.
- A "no difference" result needs a non-empty guard. Assert the inputs are non-empty and the
  extents match before reporting agreement.
- An uncovered branch is either dead or untested, and coverage cannot tell which. Find the
  consumer that reaches it, and delete the branch if none exists.
- A reachability verdict holds only for the configuration that produced it. Configuration
  knobs change which specializations and paths exist at all.
- A test filter that matches nothing must fail. A runner that exits green after selecting
  zero tests reports a green build for an empty run. Check the executed count.
- A gate added to suppress a symptom becomes harmful once the cause is fixed. Re-test and
  remove it after the real fix lands.
- A new test target nobody runs proves nothing and drags a boilerplate main with it. Before
  adding one, check which targets each CI workflow builds and runs (an aggregate helper target,
  or `./test` with no args); when any path skips the new target, fold the cases into a suite
  every path already builds instead.
- A check that compares a uniform value across identical lanes cannot see a bit moved between
  lanes, because donor and receiver hold the same bits. Detect cross-lane leakage with patterns
  that differ per lane; claim only what the input can distinguish.
- A latent wrong-answer finding becomes a failing test, not a note. If the test passes, the
  finding was wrong.

## Build hygiene

- Set the standard as a target property. Warnings, sanitizers and optimization stay
  consistent across the whole binary: mixed settings break the one-definition rule.
- Reproducible builds: override `__DATE__`/`__TIME__` (`SOURCE_DATE_EPOCH`, `/Brepro`) and stamp out path-dependent `__FILE__` values.
- Build and test in at least two configurations, debug with assertions and sanitizers, and
  optimized. A defect only at `-O2` is usually undefined behaviour.
- Read build success from the build's own exit code, never from a piped command's.
- Cache compilation with `ccache` or `sccache`, and disable the cache only when measuring
  compile time.
- Long builds and sweeps run in the background with a progress check, never a blocking wait.
- Cap parallelism to what the machine can serve, especially a shared one, and reduce it under
  memory pressure, never by removing what is built.

## CI

- CI runs the developer's commands, on the same standard, with warnings as errors.
- A matrix over the supported compilers and standards, plus one sanitizer job.
- Fail on a new warning, a new analyzer finding, or a formatting difference.
- Keep the pipeline fast. A slow pipeline gets bypassed.
- Share configure, build and test options through CMake Presets so everyone invokes the build identically.

## What evidence a change needs

| Change | Evidence |
|---|---|
| behaviour | a test that fails before and passes after |
| refactor | the existing tests, unchanged, plus a review of the diff |
| bug fix | a regression test reproducing the report |
| performance | profile or counters or assembly, minimum over repetitions, interleaved with an unchanged control |
| build change | the build time and the artifact, before and after |
| interface | a compile test of a consumer, and the header's standalone compilation |
