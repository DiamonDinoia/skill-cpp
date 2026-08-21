# Running a benchmark whose number survives review

Load before designing a timing run or quoting a speedup. `performance.md` says which lever
to pull. This file says how to prove it moved anything.

## The baseline decides the answer

- The baseline is the honest alternative: the best existing implementation, tuned, same
  flags, same problem, same accuracy. A strawman inflates the win and review will find it.
  Strawmen include an unoptimized reference, a lower-precision result, and a variant that
  skips setup the new code also skips.
- Re-measure against the current mainline, not the number in the issue. Two changes on one
  bottleneck share a base, so the second one's payoff shrinks. A win against an older base is
  arithmetic, not a result.
- A control arm is mandatory: cells the change cannot affect. Their delta is the resolution
  floor, so a claimed 3% win is not a win when untouched cells move 5%. If the control moves,
  the table is void. Fix the harness first.

## The fixture must be the real thing

- Copy the production declaration: container type, alignment, stride and padding policy,
  element type. A contiguous array benchmarking a routine the application calls with a
  padded, strided view measures a different function.
- Audit for hidden copies before believing any result, especially a vectorization or
  zero-copy claim. One by-value parameter, one loop over a temporary, one conversion at the
  call boundary, and the benchmark measures the copy.
- Measure what the shipped selector elects. When the code picks an implementation from sizes,
  thread count or hardware, a hand-written grid over implementations measures a policy that
  never ships. Drive the real entry point and print which arm ran.
- A microbenchmark must hit a parameter value the workload instantiates. Confirm from the
  end-to-end run that the size, type and template argument occur there.
- Build the probe with production optimization. A probe without the project's flags, or
  written so the compiler cannot inline it, measures the probe. Confirm the emitted code
  still contains the instruction under study.
- Before benchmarking a deletion, prove the branch is reachable. A deletion no input reaches
  shows a free win.

## Taking the measurement

- Minimum over repetitions per cell, then aggregate. Noise is one-sided: every perturbation
  adds time. Mean and median track the noise, the minimum tracks the machine.
- Interleave the arms and discard the first round. Sequential A-then-B manufactures wins from
  frequency ramp, cache warming and page placement. Alternate the destination buffer too,
  because page placement follows whichever arm touched the allocation first.
- Pin to a verified-idle physical core. Read the CPU-to-core map first: a "different" core is
  often a hardware thread on the same physical core, sharing the first two cache levels, and
  nothing partitions the last level. Pinning reduces migration, it does not isolate the
  memory hierarchy.
- Deterministic instruction counts do not imply deterministic cycles. To count executed work,
  difference counters between two runs with different repetition counts, cancelling setup.
- Fix the environment: same machine, governor, thread count and allocator, no concurrent
  build. Record all of it.

## Reading the result

- The unchanged cells are the error bar. Anything inside their spread is not a finding.
- An aggregate's sign is a property of the cell list: the same two binaries give opposite
  geometric means under two cell mixes. Quote an aggregate only with its exact cell list, and
  choose the cells from the question, never after seeing the numbers.
- Per-cell deltas compare only within one invocation. Runs with different size lists share no
  baseline, so do not subtract across them.
- A high-thread claim cannot be settled at low thread counts. Contention, false sharing and
  bandwidth appear at scale. Measure at the claimed count and at one, and report both.
- Wall time is not the workload. Difference the total against the summed phases. The
  remainder is setup, allocation or I/O the phase timings hide.
- A per-stage claim needs an arm that skips the stage. Timing it before and after a change
  shows the change, not what the stage costs.

## The harness itself lies in specific ways

- Prove both binaries are distinct and fresh. A piped build reports the exit status of the
  last command in the pipe, so a failed build leaves the old binary and the A/B compares a
  binary against itself. Check timestamps and object hashes.
- A benchmark that ignores unknown flags measures the default. Confirm the flag exists and
  the run echoes the configuration it used.
- A forcing knob applies everywhere, setup code included, so the measured delta covers more
  than the region under study.
- Keep the raw output and re-derive every quoted figure from it, not from a note. Copy the
  files out of any directory the system may reclaim.
- For a compile-time comparison, prove the compiler cache is off. Otherwise the second build
  measures the cache.

## Scope and reporting

- Run the minimum benchmark that decides the question. Deciding cells first, stream results,
  stop when the answer is determined, and say what was skipped.
- One measurement, one change. A commit bundling an unmeasured "while I was here"
  optimization with a measured one has no attributable result.
- Every stored number carries its conditions: machine, compiler and version, flags, thread
  count, input sizes, date, command. Without them it cannot be reproduced and is worth
  nothing six months later.
